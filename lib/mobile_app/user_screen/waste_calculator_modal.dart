import 'package:flutter/material.dart';

class WasteCalculatorModal extends StatefulWidget {
  const WasteCalculatorModal({super.key});

  @override
  State<WasteCalculatorModal> createState() => _WasteCalculatorModalState();
}

class _WasteCalculatorModalState extends State<WasteCalculatorModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Form controllers
  final _householdSizeController = TextEditingController();
  final _weeklyWasteController = TextEditingController();

  // State variables
  final Set<String> _selectedWasteTypes = <String>{};
  double _estimatedWeeklyWaste = 0.0;
  double _estimatedMonthlyWaste = 0.0;
  double _estimatedYearlyWaste = 0.0;
  double _carbonFootprint = 0.0;
  List<String> _recommendations = [];

  // Waste types data
  final List<Map<String, dynamic>> _wasteTypes = [
    {
      'name': 'Plastic',
      'icon': Icons.local_drink_rounded,
      'color': const Color(0xFF2196F3),
      'weight': 0.5, // kg per week per person
      'carbonFactor': 2.5, // kg CO2 per kg
    },
    {
      'name': 'Paper',
      'icon': Icons.description_rounded,
      'color': const Color(0xFF4CAF50),
      'weight': 0.8,
      'carbonFactor': 1.2,
    },
    {
      'name': 'Glass',
      'icon': Icons.wine_bar_rounded,
      'color': const Color(0xFF9C27B0),
      'weight': 0.3,
      'carbonFactor': 0.8,
    },
    {
      'name': 'Metal',
      'icon': Icons.build_rounded,
      'color': const Color(0xFFFF9800),
      'weight': 0.2,
      'carbonFactor': 3.0,
    },
    {
      'name': 'Organic',
      'icon': Icons.eco_rounded,
      'color': const Color(0xFF8BC34A),
      'weight': 1.5,
      'carbonFactor': 0.5,
    },
    {
      'name': 'Electronics',
      'icon': Icons.devices_rounded,
      'color': const Color(0xFF607D8B),
      'weight': 0.1,
      'carbonFactor': 15.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _householdSizeController.dispose();
    _weeklyWasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            _slideAnimation.value * MediaQuery.of(context).size.height,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calculate_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waste Calculator',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              'Estimate your environmental impact',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputSection(),
                        const SizedBox(height: 24),
                        _buildWasteTypesSection(),
                        const SizedBox(height: 24),
                        _buildCalculateButton(),
                        const SizedBox(height: 24),
                        if (_estimatedWeeklyWaste > 0) _buildResultsSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Household Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _householdSizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Household Size',
                    hintText: 'Number of people',
                    prefixIcon: const Icon(Icons.people_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _weeklyWasteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weekly Waste (kg)',
                    hintText: 'Optional',
                    prefixIcon: const Icon(Icons.scale_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWasteTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Waste Types',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _wasteTypes.length,
          itemBuilder: (context, index) {
            final wasteType = _wasteTypes[index];
            final isSelected = _selectedWasteTypes.contains(wasteType['name']);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedWasteTypes.remove(wasteType['name']);
                  } else {
                    _selectedWasteTypes.add(wasteType['name']);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? wasteType['color'].withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? wasteType['color'] : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      wasteType['icon'],
                      color: isSelected ? wasteType['color'] : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        wasteType['name'],
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? wasteType['color']
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: wasteType['color'],
                        size: 16,
                      ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _calculateWaste,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Calculate My Impact',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Impact Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  'Weekly',
                  '${_estimatedWeeklyWaste.toStringAsFixed(1)} kg',
                  Icons.calendar_view_week_rounded,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  'Monthly',
                  '${_estimatedMonthlyWaste.toStringAsFixed(1)} kg',
                  Icons.calendar_month_rounded,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  'Yearly',
                  '${_estimatedYearlyWaste.toStringAsFixed(1)} kg',
                  Icons.calendar_today_rounded,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  'Carbon Footprint',
                  '${_carbonFootprint.toStringAsFixed(1)} kg CO₂',
                  Icons.eco_rounded,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_recommendations.isNotEmpty) ...[
            const Text(
              'Personalized Recommendations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ..._recommendations.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  void _calculateWaste() {
    final householdSize = int.tryParse(_householdSizeController.text) ?? 1;
    final weeklyWaste = double.tryParse(_weeklyWasteController.text);

    // Validate inputs
    if (householdSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid household size'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (weeklyWaste != null && weeklyWaste > 0) {
      // Use user input if provided
      _estimatedWeeklyWaste = weeklyWaste;
      // For user input, estimate carbon footprint based on average waste composition
      _carbonFootprint = weeklyWaste * 2.0; // Average carbon factor
    } else if (_selectedWasteTypes.isNotEmpty) {
      // Calculate based on selected waste types
      _estimatedWeeklyWaste = 0;
      _carbonFootprint = 0;
      for (final wasteType in _wasteTypes) {
        if (_selectedWasteTypes.contains(wasteType['name'])) {
          _estimatedWeeklyWaste += wasteType['weight'] * householdSize;
          _carbonFootprint +=
              wasteType['weight'] * householdSize * wasteType['carbonFactor'];
        }
      }
    } else {
      // No input provided
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter weekly waste amount or select waste types',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _estimatedMonthlyWaste = _estimatedWeeklyWaste * 4.33;
    _estimatedYearlyWaste = _estimatedWeeklyWaste * 52;

    _generateRecommendations();

    setState(() {});
  }

  void _generateRecommendations() {
    _recommendations.clear();

    if (_estimatedWeeklyWaste > 10) {
      _recommendations.add('Consider reducing single-use items');
    }

    if (_selectedWasteTypes.contains('Plastic')) {
      _recommendations.add('Switch to reusable containers and bags');
    }

    if (_selectedWasteTypes.contains('Paper')) {
      _recommendations.add('Go digital when possible and recycle paper');
    }

    if (_selectedWasteTypes.contains('Organic')) {
      _recommendations.add('Start composting to reduce organic waste');
    }

    if (_carbonFootprint > 50) {
      _recommendations.add(
        'Focus on recycling to reduce your carbon footprint',
      );
    }

    if (_recommendations.isEmpty) {
      _recommendations.add('Great job! Keep up the sustainable practices');
    }
  }
}
