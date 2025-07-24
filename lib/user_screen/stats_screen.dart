import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _listAnimationController;
  late AnimationController _progressAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  final List<Map<String, dynamic>> wasteStats = const [
    {
      "category": "Plastic",
      "count": 25,
      "color": Color(0xFF4FC3F7),
      "icon": Icons.water_drop,
    },
    {
      "category": "Paper",
      "count": 18,
      "color": Color(0xFF8D6E63),
      "icon": Icons.description,
    },
    {
      "category": "Glass",
      "count": 12,
      "color": Color(0xFF66BB6A),
      "icon": Icons.local_drink,
    },
    {
      "category": "Metal",
      "count": 7,
      "color": Color(0xFF90A4AE),
      "icon": Icons.hardware,
    },
    {
      "category": "Cardboard",
      "count": 10,
      "color": Color(0xFFFFB74D),
      "icon": Icons.inventory_2,
    },
    {
      "category": "Trash",
      "count": 5,
      "color": Color(0xFFE57373),
      "icon": Icons.delete,
    },
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations sooner
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _listAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _listAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  int get totalItems =>
      wasteStats.fold(0, (sum, item) => sum + (item["count"] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('SortCycle'),
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Animated Header Section
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 800),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.rotate(
                                        angle: value * 0.5,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.bar_chart,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Waste Statistics",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Environmental Impact Overview",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    TweenAnimationBuilder<int>(
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      tween: IntTween(
                                        begin: 0,
                                        end: totalItems,
                                      ),
                                      builder: (context, value, child) {
                                        return Column(
                                          children: [
                                            Text(
                                              "$value",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              "Total Items",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white30,
                                    ),
                                    TweenAnimationBuilder<int>(
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      tween: IntTween(
                                        begin: 0,
                                        end: wasteStats.length,
                                      ),
                                      builder: (context, value, child) {
                                        return Column(
                                          children: [
                                            Text(
                                              "$value",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              "Categories",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Animated Category List Section Header
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _listAnimationController,
                builder: (context, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(-1.0, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _listAnimationController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: FadeTransition(
                      opacity: _listAnimationController,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.list_alt,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Detailed Breakdown",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E2E2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Animated List Items
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final stat = wasteStats[index];
                final percentage = ((stat["count"] as int) / totalItems * 100);

                return AnimatedBuilder(
                  animation: _listAnimationController,
                  builder: (context, child) {
                    final itemAnimation =
                        Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _listAnimationController,
                            curve: Interval(
                              index * 0.1,
                              (0.6 + (index * 0.1)).clamp(
                                0.0,
                                1.0,
                              ), // ✅ Safe clamp
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        );

                    final itemFade = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _listAnimationController,
                            curve: Interval(
                              index * 0.1,
                              (0.6 + (index * 0.1)).clamp(
                                0.0,
                                1.0,
                              ), // ✅ Fix here too
                              curve: Curves.easeInOut,
                            ),
                          ),
                        );

                    return SlideTransition(
                      position: itemAnimation,
                      child: FadeTransition(
                        opacity: itemFade,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                // Add haptic feedback
                                // HapticFeedback.lightImpact();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      duration: Duration(
                                        milliseconds: 600 + (index * 100),
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: (stat["color"] as Color)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              stat["icon"],
                                              color: stat["color"],
                                              size: 28,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stat["category"],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color(0xFF2E2E2E),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${percentage.toStringAsFixed(1)}% of total waste",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: AnimatedBuilder(
                                              animation: _progressAnimation,
                                              builder: (context, child) {
                                                return FractionallySizedBox(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  widthFactor:
                                                      (percentage / 100) *
                                                      _progressAnimation.value,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: stat["color"],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    TweenAnimationBuilder<int>(
                                      duration: Duration(
                                        milliseconds: 1000 + (index * 100),
                                      ),
                                      tween: IntTween(
                                        begin: 0,
                                        end: stat["count"],
                                      ),
                                      builder: (context, value, child) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "$value",
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2E2E2E),
                                              ),
                                            ),
                                            Text(
                                              "items",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }, childCount: wasteStats.length),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
