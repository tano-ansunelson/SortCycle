import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Last 30 Days';
  String _selectedMetric = 'Users';

  final List<String> _periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year'
  ];

  final List<String> _metrics = [
    'Users',
    'Pickup Requests',
    'Marketplace Items',
    'Revenue',
    'Waste Collected'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics & Insights',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monitor platform performance and user engagement',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _exportAnalytics();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Period and Metric Selectors
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _periods.map((period) => DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMetric,
                    decoration: InputDecoration(
                      labelText: 'Primary Metric',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _metrics.map((metric) => DropdownMenuItem(
                      value: metric,
                      child: Text(metric),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMetric = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Key Metrics Cards
            Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                return GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      title: 'Total Users',
                      value: adminProvider.totalUsers.toString(),
                      change: '+12%',
                      changeType: 'positive',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    _buildMetricCard(
                      title: 'Active Collectors',
                      value: adminProvider.totalCollectors.toString(),
                      change: '+8%',
                      changeType: 'positive',
                      icon: Icons.local_shipping,
                      color: Colors.orange,
                    ),
                    _buildMetricCard(
                      title: 'Pickup Requests',
                      value: adminProvider.totalPickupRequests.toString(),
                      change: '+15%',
                      changeType: 'positive',
                      icon: Icons.recycling,
                      color: Colors.green,
                    ),
                    _buildMetricCard(
                      title: 'Marketplace Items',
                      value: adminProvider.totalMarketplaceItems.toString(),
                      change: '+5%',
                      changeType: 'positive',
                      icon: Icons.store,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Charts Section
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildChartCard(
                    title: 'User Growth Trend',
                    subtitle: 'New user registrations over time',
                    child: _buildUserGrowthChart(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildChartCard(
                    title: 'Waste Collection',
                    subtitle: 'Monthly collection volume',
                    child: _buildWasteCollectionChart(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Additional Analytics
            Row(
              children: [
                Expanded(
                  child: _buildChartCard(
                    title: 'Pickup Request Status',
                    subtitle: 'Distribution of request statuses',
                    child: _buildPickupStatusChart(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildChartCard(
                    title: 'Top Categories',
                    subtitle: 'Most popular marketplace categories',
                    child: _buildTopCategoriesChart(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Performance Metrics
            _buildPerformanceMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String change,
    required String changeType,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeType == 'positive' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Placeholder chart - replace with actual chart library
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'User Growth Chart',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Chart will be implemented with a chart library',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartLegend('New Users', Colors.blue),
              _buildChartLegend('Returning Users', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWasteCollectionChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Placeholder chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Waste Collection Chart',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartLegend('Organic', Colors.green),
              _buildChartLegend('Recyclable', Colors.blue),
              _buildChartLegend('Other', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupStatusChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Placeholder chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.donut_large,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Pickup Status Chart',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildChartLegend('Pending', Colors.orange),
              _buildChartLegend('Approved', Colors.blue),
              _buildChartLegend('Completed', Colors.green),
              _buildChartLegend('Cancelled', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Placeholder chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Top Categories Chart',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildChartLegend('Electronics', Colors.purple),
              _buildChartLegend('Furniture', Colors.brown),
              _buildChartLegend('Clothing', Colors.pink),
              _buildChartLegend('Books', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    title: 'Average Response Time',
                    value: '2.3 hours',
                    target: 'Under 4 hours',
                    status: 'good',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildPerformanceMetric(
                    title: 'Pickup Success Rate',
                    value: '94.2%',
                    target: 'Above 90%',
                    status: 'excellent',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildPerformanceMetric(
                    title: 'User Satisfaction',
                    value: '4.6/5.0',
                    target: 'Above 4.0',
                    status: 'excellent',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildPerformanceMetric(
                    title: 'Platform Uptime',
                    value: '99.8%',
                    target: 'Above 99%',
                    status: 'excellent',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String title,
    required String value,
    required String target,
    required String status,
  }) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'excellent':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'good':
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'critical':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: $target',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _exportAnalytics() {
    // TODO: Implement analytics export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
