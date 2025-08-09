// Enhanced Beautiful WastePickupFormUpdated
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/user_screen/user_request_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' show DateFormat;

class WastePickupFormUpdated extends StatefulWidget {
  final String userId;

  const WastePickupFormUpdated({super.key, required this.userId});

  @override
  State<WastePickupFormUpdated> createState() => _WastePickupFormUpdatedState();
}

class _WastePickupFormUpdatedState extends State<WastePickupFormUpdated>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  //final _nameController = TextEditingController();
  //final _phoneController = TextEditingController();
  final _townController = TextEditingController();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Location variables
  Position? _currentPosition;
  bool _isLocationLoading = false;
  String _locationStatus = "Location not set";

  // Date and time variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final Set<String> _selectedCategories = <String>{};

  // Collectors
  List<Map<String, dynamic>> _nearbyCollectors = [];
  String? _selectedCollectorId;
  bool _isLoadingCollectors = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Start animations
    _slideController.forward();
    _fadeController.forward();

    _townController.addListener(() {
      final town = _townController.text.trim();
      if (town.isNotEmpty && town.length >= 3) {
        // _fetchNearbyCollectors();
        // Debounce to prevent multiple rapid calls
        _debounceFetch(town);
      }
    });
  }

  // Debounce helper
  Timer? _debounce;
  void _debounceFetch(String town) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchNearbyCollectors();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    // _nameController.dispose();
    // _phoneController.dispose();
    _townController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Date and time selection methods
  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    HapticFeedback.lightImpact();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      // Check if time is between 9AM and 5PM
      final int pickedMinutes = picked.hour * 60 + picked.minute;
      const int minMinutes = 9 * 60; // 9:00 AM
      const int maxMinutes = 17 * 60; // 5:00 PM

      if (pickedMinutes >= minMinutes && pickedMinutes <= maxMinutes) {
        setState(() {
          _selectedTime = picked;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Please select a time between 9:00 AM and 5:00 PM'),
          ),
        );
      }
    }
  }

  // Get Current Location
  Future<void> _getCurrentLocation() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLocationLoading = true;
      _locationStatus = "Getting location...";
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus = "📍 Location captured successfully";
        _isLocationLoading = false;
      });

      // HapticFeedback.successFeedback();
    } catch (e) {
      setState(() {
        _locationStatus = "❌ Error: ${e.toString()}";
        _isLocationLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _fetchNearbyCollectors() async {
    setState(() {
      _isLoadingCollectors = true;
      _nearbyCollectors.clear();
      _selectedCollectorId = null;
    });

    try {
      String userTown = _townController.text.trim().toLowerCase();

      if (userTown.isEmpty) {
        throw Exception('Please enter your town to fetch collectors.');
      }

      QuerySnapshot collectorsSnapshot = await FirebaseFirestore.instance
          .collection('collectors')
          .where('isActive', isEqualTo: true)
          .where('town', isEqualTo: userTown)
          .get();

      List<Map<String, dynamic>> townCollectors = collectorsSnapshot.docs.map((
        doc,
      ) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Collector',
          'phone': data['phone'] ?? '',
          'town': data['town'],
        };
      }).toList();

      setState(() {
        _nearbyCollectors = townCollectors;
        _isLoadingCollectors = false;
      });

      if (_nearbyCollectors.isEmpty) {
        _showSnackBar(
          'No collectors found in your town.',
          Colors.orange.shade600,
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingCollectors = false;
      });
      _showSnackBar(
        'Failed to fetch collectors: ${e.toString()}',
        Colors.red.shade600,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Fetch Nearby Collectors
  // Future<void> _fetchNearbyCollectors() async {
  //   setState(() {
  //     _isLoadingCollectors = true;
  //     _nearbyCollectors.clear();
  //     _selectedCollectorId = null;
  //   });

  //   try {
  //     String userTown = _townController.text.trim().toLowerCase();

  //     if (userTown.isEmpty) {
  //       throw Exception('Please enter your town to fetch collectors.');
  //     }

  //     QuerySnapshot collectorsSnapshot = await FirebaseFirestore.instance
  //         .collection('collectors')
  //         .where('isActive', isEqualTo: true)
  //         .where('town', isEqualTo: userTown)
  //         .get();

  //     List<Map<String, dynamic>> townCollectors = [];

  //     for (QueryDocumentSnapshot doc in collectorsSnapshot.docs) {
  //       Map<String, dynamic> collectorData = doc.data() as Map<String, dynamic>;

  //       townCollectors.add({
  //         'id': doc.id,
  //         'name': collectorData['name'] ?? 'Unknown Collector',
  //         'phone': collectorData['phone'] ?? '',
  //         'town': collectorData['town'],
  //       });
  //     }

  //     setState(() {
  //       _nearbyCollectors = townCollectors;
  //       _isLoadingCollectors = false;
  //     });

  //     if (_nearbyCollectors.isEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: const Text('No collectors found in your town.'),
  //           backgroundColor: Colors.orange.shade600,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isLoadingCollectors = false;
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to fetch collectors: ${e.toString()}'),
  //         backgroundColor: Colors.red.shade600,
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //       ),
  //     );
  //   }
  // }

  Future<void> _submitPickupRequest() async {
    HapticFeedback.mediumImpact();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showErrorSnackBar('Please select a pickup date');
      return;
    }

    if (_selectedTime == null) {
      _showErrorSnackBar('Please select a pickup time');
      return;
    }

    if (_currentPosition == null) {
      _showErrorSnackBar('Please set your location first');
      return;
    }

    if (_selectedCollectorId == null) {
      _showErrorSnackBar('Please select a collector');
      return;
    }

    try {
      _showLoadingDialog();

      // 🔸 Fetch user info from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        Navigator.of(context).pop(); // close loading dialog
        _showErrorSnackBar('User data not found');
        return;
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'Unknown';
      final userPhone = userData['phone'] ?? '';
      //final userTown = userData['town'] ?? '';

      DateTime pickupDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final selectedCollector = _nearbyCollectors.firstWhere(
        (collector) => collector['id'] == _selectedCollectorId,
        orElse: () => {},
      );

      final collectorName = selectedCollector['name'] ?? 'Unknown Collector';

      // 🔸 Save pickup request
      await FirebaseFirestore.instance.collection('pickup_requests').add({
        'userId': widget.userId,
        'userName': userName,
        'userPhone': userPhone,
        'userTown': _townController.text.trim(),
        'userLatitude': _currentPosition!.latitude,
        'userLongitude': _currentPosition!.longitude,
        'collectorId': _selectedCollectorId,
        'collectorName': collectorName,
        'pickupDate': Timestamp.fromDate(pickupDateTime),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(); // Close loading
      _showSuccessDialog();
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      _showErrorSnackBar('Failed to submit request: ${e.toString()}');
    }
  }

  // Submit Pickup Request
  // Future<void> _submitPickupRequest() async {
  //   HapticFeedback.mediumImpact();

  //   if (!_formKey.currentState!.validate()) return;

  //   // Validation checks with beautiful snackbars
  //   // if (_selectedCategories.isEmpty) {
  //   //   _showErrorSnackBar('Please select at least one waste category');
  //   //   return;
  //   // }

  //   if (_selectedDate == null) {
  //     _showErrorSnackBar('Please select a pickup date');
  //     return;
  //   }

  //   if (_selectedTime == null) {
  //     _showErrorSnackBar('Please select a pickup time');
  //     return;
  //   }

  //   if (_currentPosition == null) {
  //     _showErrorSnackBar('Please set your location first');
  //     return;
  //   }

  //   if (_selectedCollectorId == null) {
  //     _showErrorSnackBar('Please select a collector');
  //     return;
  //   }

  //   try {
  //     // Show beautiful loading dialog
  //     _showLoadingDialog();

  //     DateTime pickupDateTime = DateTime(
  //       _selectedDate!.year,
  //       _selectedDate!.month,
  //       _selectedDate!.day,
  //       _selectedTime!.hour,
  //       _selectedTime!.minute,
  //     );

  //     final selectedCollector = _nearbyCollectors.firstWhere(
  //       (collector) => collector['id'] == _selectedCollectorId,
  //       orElse: () => {},
  //     );
  //     final collectorName = selectedCollector['name'] ?? 'Unknown Collector';

  //     await FirebaseFirestore.instance.collection('pickup_requests').add({
  //       'userId': widget.userId,
  //       //'userName': _nameController.text.trim(),
  //       'userPhone': _phoneController.text.trim(),
  //       'userTown': _townController.text.trim(),
  //      // 'wasteCategories': _selectedCategories.toList(),
  //       'userLatitude': _currentPosition!.latitude,
  //       'userLongitude': _currentPosition!.longitude,
  //       'collectorId': _selectedCollectorId,
  //       'collectorName': collectorName,
  //       'pickupDate': Timestamp.fromDate(pickupDateTime),
  //       'status': 'pending',
  //       'createdAt': FieldValue.serverTimestamp(),
  //     });

  //     Navigator.of(context).pop(); // Close loading dialog
  //     // HapticFeedback.successFeedback();
  //     _showSuccessDialog();
  //   } catch (e) {
  //     Navigator.of(context).pop(); // Close loading dialog
  //     _showErrorSnackBar('Failed to submit request: ${e.toString()}');
  //   }
  // }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Submitting your request...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                "This won't take long",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Success!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your pickup request has been submitted successfully. You can track its status in the requests tab.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetForm();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetForm();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                UserRequestsScreen(userId: widget.userId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Requests'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      // _nameController.clear();
      //_phoneController.clear();
      _townController.clear();
      _selectedCategories.clear();
      _currentPosition = null;
      _locationStatus = "Location not set";
      _nearbyCollectors.clear();
      _selectedCollectorId = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Request Pickup',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade600, Colors.green.shade800],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Icon(
                        Icons.recycling,
                        size: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),

          // Form Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // User Information Card
                          _buildAnimatedCard(
                            delay: 0,
                            child: _buildUserInfoSection(),
                          ),
                          const SizedBox(height: 16),

                          // Waste Categories Card
                          // _buildAnimatedCard(
                          //   delay: 200,
                          //   child: _buildWasteCategoriesSection(),
                          // ),
                          const SizedBox(height: 16),

                          // Schedule Card
                          _buildAnimatedCard(
                            delay: 400,
                            child: _buildScheduleSection(),
                          ),

                          const SizedBox(height: 16),

                          // Location Card
                          _buildAnimatedCard(
                            delay: 600,
                            child: _buildLocationSection(),
                          ),

                          const SizedBox(height: 16),

                          // Collector Selection Card
                          _buildAnimatedCard(
                            delay: 800,
                            child: _buildCollectorSection(),
                          ),

                          const SizedBox(height: 32),

                          // Submit Button
                          _buildAnimatedCard(
                            delay: 1000,
                            child: _buildSubmitButton(),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child, required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Your Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 24),
          // _buildStyledTextField(
          //   controller: _nameController,
          //   label: 'Full Name',
          //   icon: Icons.person_outline,
          //   validator: (value) {
          //     if (value == null || value.trim().isEmpty) {
          //       return 'Please enter your name';
          //     }
          //     return null;
          //   },
          // ),
          // const SizedBox(height: 16),
          // _buildStyledTextField(
          //   controller: _phoneController,
          //   label: 'Phone Number',
          //   icon: Icons.phone_outlined,
          //   keyboardType: TextInputType.phone,
          //   validator: (value) {
          //     if (value == null || value.trim().isEmpty) {
          //       return 'Please enter your phone number';
          //     }
          //     return null;
          //   },
          // ),
          const SizedBox(height: 16),
          _buildStyledTextField(
            controller: _townController,
            label: 'Town/City',
            icon: Icons.location_city_outlined,
            hint: 'Enter your town or city',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your town or city';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  // Widget _buildWasteCategoriesSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.green.shade50,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 Icons.category,
  //                 color: Colors.green.shade600,
  //                 size: 24,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             const Text(
  //               'Waste Categories',
  //               style: TextStyle(
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.bold,
  //                 color: Color(0xFF2E2E2E),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Select the types of waste you want to dispose of',
  //           style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
  //         ),
  //         const SizedBox(height: 20),
  //         Wrap(
  //           spacing: 12,
  //           runSpacing: 12,
  //           children: _wasteCategories.map((category) {
  //             final isSelected = _selectedCategories.contains(category['name']);
  //             return GestureDetector(
  //               onTap: () {
  //                 HapticFeedback.lightImpact();
  //                 setState(() {
  //                   if (isSelected) {
  //                     _selectedCategories.remove(category['name']);
  //                   } else {
  //                     _selectedCategories.add(category['name']);
  //                   }
  //                 });
  //               },
  //               child: AnimatedContainer(
  //                 duration: const Duration(milliseconds: 200),
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 16,
  //                   vertical: 12,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: isSelected
  //                       ? category['color'].withOpacity(0.1)
  //                       : Colors.grey.shade100,
  //                   borderRadius: BorderRadius.circular(25),
  //                   border: Border.all(
  //                     color: isSelected
  //                         ? category['color']
  //                         : Colors.grey.shade300,
  //                     width: isSelected ? 2 : 1,
  //                   ),
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(
  //                       category['icon'],
  //                       size: 18,
  //                       color: isSelected
  //                           ? category['color']
  //                           : Colors.grey.shade600,
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       category['name'],
  //                       style: TextStyle(
  //                         color: isSelected
  //                             ? category['color']
  //                             : Colors.grey.shade700,
  //                         fontWeight: isSelected
  //                             ? FontWeight.bold
  //                             : FontWeight.normal,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }).toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Pickup Schedule',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose when you want your waste to be collected',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildScheduleButton(
                  icon: Icons.calendar_today,
                  label: _selectedDate == null
                      ? 'Select Date'
                      : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                  onTap: _selectDate,
                  isSelected: _selectedDate != null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScheduleButton(
                  icon: Icons.access_time,
                  label: _selectedTime == null
                      ? 'Select Time'
                      : _selectedTime!.format(context),
                  onTap: _selectTime,
                  isSelected: _selectedTime != null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green.shade600 : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.green.shade600
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Your Location',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We need your location to find nearby collectors',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentPosition != null
                  ? Colors.green.shade50
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentPosition != null
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentPosition != null
                      ? Icons.check_circle
                      : Icons.location_off,
                  color: _currentPosition != null
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _locationStatus,
                    style: TextStyle(
                      color: _currentPosition != null
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLocationLoading ? null : _getCurrentLocation,
              icon: _isLocationLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isLocationLoading
                    ? 'Getting Location...'
                    : 'Get Current Location',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectorSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_search,
                  color: Colors.purple.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Select Collector',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from available collectors in your area',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          if (_isLoadingCollectors)
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.purple.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Finding collectors in your area...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_nearbyCollectors.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No collectors found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please enter your town to find collectors',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _nearbyCollectors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final collector = entry.value;
                  final isSelected = _selectedCollectorId == collector['id'];
                  final isLast = index == _nearbyCollectors.length - 1;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedCollectorId = collector['id'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.purple.shade50
                            : Colors.transparent,
                        borderRadius: BorderRadius.vertical(
                          top: index == 0
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottom: isLast
                              ? const Radius.circular(12)
                              : Radius.zero,
                        ),
                        border: isSelected
                            ? Border.all(
                                color: Colors.purple.shade600,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purple.shade600
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  collector['name'] ?? 'Unknown Collector',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.purple.shade700
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  collector['town'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (collector['phone']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    collector['phone'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.purple.shade600,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade600.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitPickupRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Submit Pickup Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
