// Enhanced Beautiful WastePickupFormUpdated with Today/Schedule Options
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:flutter_application_1/mobile_app/user_screen/user_request_screen.dart';
import 'package:flutter_application_1/mobile_app/services/payment_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'dart:math'; // Added for Random

class WastePickupFormUpdated extends StatefulWidget {
  final String userId;

  const WastePickupFormUpdated({super.key, required this.userId});

  @override
  State<WastePickupFormUpdated> createState() => _WastePickupFormUpdatedState();
}

class _WastePickupFormUpdatedState extends State<WastePickupFormUpdated>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
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

  // // Date and time variables
  // bool _isPickupToday = true; // New: Track if pickup is today or scheduled
  // DateTime? _selectedDate;
  // TimeOfDay? _selectedTime;

  final Set<String> _selectedCategories = <String>{};

  // Collectors
  List<Map<String, dynamic>> _nearbyCollectors = [];
  String? _selectedCollectorId;
  bool _isLoadingCollectors = false;

  // Collector schedules
  Map<String, List<DateTime>> _collectorSchedules = {};
  DateTime? _selectedScheduleDate;

  // NEW: Payment and bin selection variables
  int _selectedBinCount = 1;
  bool _isPaymentCompleted = false;
  static const double _pricePerBin = 20.0; // GH₵20 per bin
  static const int _maxBinCount = 10; // Maximum number of bins allowed

  // Emergency pickup variables
  bool _isEmergencyPickup = false;
  static const double _emergencyMultiplier = 1.5; // 50% extra for emergency

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
        _debounceFetch(town);
      } else if (town.isEmpty) {
        // Clear collector and date selections when town is cleared
        setState(() {
          _nearbyCollectors.clear();
          _selectedCollectorId = null;
          _collectorSchedules.clear();
          _selectedScheduleDate = null;
        });
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
    _townController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Date and time selection methods
  // Future<void> _selectDate() async {
  //   HapticFeedback.lightImpact();
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
  //     firstDate: DateTime.now().add(
  //       const Duration(days: 1),
  //     ), // Start from tomorrow
  //     lastDate: DateTime.now().add(const Duration(days: 30)),
  //     builder: (context, child) {
  //       return Theme(
  //         data: Theme.of(context).copyWith(
  //           colorScheme: ColorScheme.light(
  //             primary: Colors.green.shade600,
  //             onPrimary: Colors.white,
  //             surface: Colors.white,
  //             onSurface: Colors.black,
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );

  //   if (picked != null && picked != _selectedDate) {
  //     setState(() {
  //       _selectedDate = picked;
  //     });
  //   }
  // }

  // Future<void> _selectTime() async {
  //   HapticFeedback.lightImpact();

  //   // For today, check current time and set minimum time
  //   TimeOfDay initialTime;
  //   if (_isPickupToday) {
  //     final now = DateTime.now();
  //     final currentTime = TimeOfDay.fromDateTime(now);
  //     final currentMinutes = currentTime.hour * 60 + currentTime.minute;

  //     // If it's past 4 PM, don't allow today pickup
  //     if (currentMinutes >= 16 * 60) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           backgroundColor: Colors.orange,
  //           content: Text(
  //             'It\'s too late for today\'s pickup. Please schedule for tomorrow.',
  //           ),
  //         ),
  //       );
  //       return;
  //     }

  //     // Set initial time to at least 1 hour from now, but not past 5 PM
  //     final oneHourLater = now.add(const Duration(hours: 1));
  //     initialTime = TimeOfDay.fromDateTime(oneHourLater);
  //   } else {
  //     initialTime = _selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
  //   }

  //   final TimeOfDay? picked = await showTimePicker(
  //     context: context,
  //     initialTime: initialTime,
  //     builder: (context, child) {
  //       return Theme(
  //         data: Theme.of(context).copyWith(
  //           colorScheme: ColorScheme.light(
  //             primary: Colors.green.shade600,
  //             onPrimary: Colors.white,
  //             surface: Colors.white,
  //             onSurface: Colors.black,
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );

  //   if (picked != null && picked != _selectedTime) {
  //     final int pickedMinutes = picked.hour * 60 + picked.minute;
  //     const int minMinutes = 9 * 60; // 9:00 AM
  //     const int maxMinutes = 17 * 60; // 5:00 PM

  //     if (_isPickupToday) {
  //       // For today, ensure time is at least 30 minutes from now
  //       final now = DateTime.now();
  //       final minTimeToday = now.add(const Duration(minutes: 30));
  //       final minTimeTodayMinutes =
  //           minTimeToday.hour * 60 + minTimeToday.minute;

  //       if (pickedMinutes < minTimeTodayMinutes || pickedMinutes > maxMinutes) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             backgroundColor: Colors.red,
  //             content: Text(
  //               'For today\'s pickup, please select a time at least 30 minutes from now and before 5:00 PM\nCurrent time: ${TimeOfDay.fromDateTime(now).format(context)}',
  //             ),
  //           ),
  //         );
  //         return;
  //       }
  //     } else {
  //       // For scheduled pickup, check normal business hours
  //       if (pickedMinutes < minMinutes || pickedMinutes > maxMinutes) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             backgroundColor: Colors.red,
  //             content: Text('Please select a time between 9:00 AM and 5:00 PM'),
  //           ),
  //         );
  //         return;
  //       }
  //     }

  //     setState(() {
  //       _selectedTime = picked;
  //     });
  //   }
  // }

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
      _collectorSchedules.clear();
      _selectedScheduleDate = null;
    });

    try {
      String userTown = _townController.text.trim();

      if (userTown.isEmpty) {
        throw Exception('Please enter your town to fetch collectors.');
      }

      // Normalize town name for better matching
      userTown = userTown.toLowerCase();

      // Validate town name (should be at least 2 characters)
      if (userTown.length < 2) {
        throw Exception(
          'Please enter a valid town name (at least 2 characters).',
        );
      }

      // First, get all active collectors
      QuerySnapshot collectorsSnapshot = await FirebaseFirestore.instance
          .collection('collectors')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> allCollectors = collectorsSnapshot.docs.map((
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

      // Now filter collectors who have the user's town in their weekly schedules
      List<Map<String, dynamic>> townCollectors = [];
      Map<String, List<DateTime>> collectorSchedules = {};

      // Use Future.wait to fetch all schedules concurrently for better performance
      List<Future<Map<String, dynamic>?>> scheduleFutures = [];

      for (final collector in allCollectors) {
        final collectorId = collector['id'];
        scheduleFutures.add(
          _fetchCollectorScheduleWithCollector(
            collectorId,
            userTown,
            collector,
          ),
        );
      }

      // Wait for all schedule fetches to complete with timeout
      final scheduleResults = await Future.wait(
        scheduleFutures.map(
          (future) => future.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Schedule fetch timeout for a collector');
              return null;
            },
          ),
        ),
        eagerError: false,
      );

      // Process results and filter collectors
      int totalCollectors = allCollectors.length;
      int collectorsWithSchedules = 0;

      for (final result in scheduleResults) {
        if (result != null && result['schedules'].isNotEmpty) {
          final collector = result['collector'] as Map<String, dynamic>;
          final schedules = result['schedules'] as List<DateTime>;

          townCollectors.add(collector);
          collectorSchedules[collector['id']] = schedules;
          collectorsWithSchedules++;

          // Debug logging
          print(
            'Collector ${collector['name']} (${collector['town']}) has ${schedules.length} scheduled dates for town: $userTown',
          );
        }
      }

      print(
        'Found $collectorsWithSchedules out of $totalCollectors collectors with schedules for town: $userTown',
      );

      setState(() {
        _nearbyCollectors = townCollectors;
        _collectorSchedules = collectorSchedules;
        _isLoadingCollectors = false;
      });

      // Auto-select a random collector if available
      if (_nearbyCollectors.isNotEmpty) {
        // All collectors in townCollectors now have schedules for this town
        final random = Random();
        final randomIndex = random.nextInt(_nearbyCollectors.length);
        final selectedCollector = _nearbyCollectors[randomIndex];

        setState(() {
          _selectedCollectorId = selectedCollector['id'];
        });
        _showSnackBar(
          'Collector with scheduled dates selected: ${selectedCollector['name']}',
          Colors.green.shade600,
        );
      } else {
        // Check if we found any collectors at all
        if (allCollectors.isEmpty) {
          _showSnackBar(
            'No active collectors found in the system. Please try again later.',
            Colors.red.shade600,
          );
        } else {
          // Try to find similar town names to help the user
          final similarTowns = _findSimilarTowns(userTown, allCollectors);
          if (similarTowns.isNotEmpty) {
            _showSnackBar(
              'No collectors found for "$userTown". Did you mean: ${similarTowns.take(3).join(', ')}?',
              Colors.orange.shade600,
            );
          } else {
            _showSnackBar(
              'No collectors have scheduled pickups in $userTown. Your request will be queued and assigned when a collector becomes available.',
              Colors.orange.shade600,
            );
          }
        }
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

  // Fetch collector's schedule for a specific town (returns collector data with schedules)
  Future<Map<String, dynamic>?> _fetchCollectorScheduleWithCollector(
    String collectorId,
    String userTown,
    Map<String, dynamic> collector,
  ) async {
    try {
      final scheduleDoc = await FirebaseFirestore.instance
          .collection('weekly_schedules')
          .doc(collectorId)
          .get();

      if (!scheduleDoc.exists) {
        return null;
      }

      final scheduleData = scheduleDoc.data();
      final schedule = scheduleData?['schedule'] as Map<String, dynamic>? ?? {};

      List<DateTime> availableDates = [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final entry in schedule.entries) {
        final dateKey = entry.key;
        final scheduledTowns = entry.value as List<dynamic>? ?? [];

        // Check if the user's town is in the collector's scheduled towns for this date
        if (scheduledTowns.isNotEmpty &&
            scheduledTowns.any((scheduledTown) {
              final scheduledTownStr = scheduledTown
                  .toString()
                  .trim()
                  .toLowerCase();
              final userTownStr = userTown.trim().toLowerCase();

              // Exact match
              if (scheduledTownStr == userTownStr) return true;

              // Partial match (e.g., "Accra Central" matches "Accra")
              if (scheduledTownStr.contains(userTownStr) ||
                  userTownStr.contains(scheduledTownStr))
                return true;

              return false;
            })) {
          // Debug logging
          final matchedTown = scheduledTowns.firstWhere((scheduledTown) {
            final scheduledTownStr = scheduledTown
                .toString()
                .trim()
                .toLowerCase();
            final userTownStr = userTown.trim().toLowerCase();
            return scheduledTownStr == userTownStr ||
                scheduledTownStr.contains(userTownStr) ||
                userTownStr.contains(scheduledTownStr);
          });
          print(
            'Found match: User town "$userTown" matches scheduled town "$matchedTown" for date $dateKey',
          );
          try {
            final date = DateFormat('yyyy-MM-dd').parse(dateKey);
            final scheduleDate = DateTime(date.year, date.month, date.day);

            // Only add dates that are today or in the future
            if (scheduleDate.isAfter(today) ||
                scheduleDate.isAtSameMomentAs(today)) {
              availableDates.add(scheduleDate);
            }
          } catch (e) {
            // Skip invalid date formats
            continue;
          }
        }
      }

      // Sort dates chronologically
      availableDates.sort();

      // Return collector data with schedules
      return {'collector': collector, 'schedules': availableDates};
    } catch (e) {
      print('Error fetching collector schedule for ${collector['name']}: $e');
      return null;
    }
  }

  // Fetch collector's schedule for a specific town (legacy method for backward compatibility)
  // ignore: unused_element
  Future<List<DateTime>> _fetchCollectorSchedule(
    String collectorId,
    String userTown,
  ) async {
    try {
      final scheduleDoc = await FirebaseFirestore.instance
          .collection('weekly_schedules')
          .doc(collectorId)
          .get();

      if (!scheduleDoc.exists) {
        return [];
      }

      final scheduleData = scheduleDoc.data();
      final schedule = scheduleData?['schedule'] as Map<String, dynamic>? ?? {};

      List<DateTime> availableDates = [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final entry in schedule.entries) {
        final dateKey = entry.key;
        final scheduledTowns = entry.value as List<dynamic>? ?? [];

        // Check if the user's town is in the collector's scheduled towns for this date
        if (scheduledTowns.isNotEmpty &&
            scheduledTowns.any((scheduledTown) {
              final scheduledTownStr = scheduledTown
                  .toString()
                  .trim()
                  .toLowerCase();
              final userTownStr = userTown.trim().toLowerCase();

              // Exact match
              if (scheduledTownStr == userTownStr) return true;

              // Partial match (e.g., "Accra Central" matches "Accra")
              if (scheduledTownStr.contains(userTownStr) ||
                  userTownStr.contains(scheduledTownStr))
                return true;

              return false;
            })) {
          try {
            final date = DateFormat('yyyy-MM-dd').parse(dateKey);
            final scheduleDate = DateTime(date.year, date.month, date.day);

            // Only add dates that are today or in the future
            if (scheduleDate.isAfter(today) ||
                scheduleDate.isAtSameMomentAs(today)) {
              availableDates.add(scheduleDate);
            }
          } catch (e) {
            // Skip invalid date formats
            continue;
          }
        }
      }

      // Sort dates chronologically
      availableDates.sort();
      return availableDates;
    } catch (e) {
      print('Error fetching collector schedule: $e');
      return [];
    }
  }

  void _onCollectorSelected(String collectorId) {
    setState(() {
      _selectedCollectorId = collectorId;
      // _selectedScheduleDate = null; // Reset selected date when collector changes
    });
  }

  void _onScheduleDateSelected(DateTime date) {
    setState(() {
      _selectedScheduleDate = date;
      // _selectedDate = date; // Update the main selected date
    });
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

  Future<void> _submitPickupRequest() async {
    HapticFeedback.mediumImpact();

    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      _showErrorSnackBar('Please set your location first');
      return;
    }

    // Validate collector and scheduled date selection if collector is selected
    if (_selectedCollectorId != null) {
      final availableDates = _collectorSchedules[_selectedCollectorId];
      if (availableDates != null && availableDates.isNotEmpty) {
        if (_selectedScheduleDate == null) {
          _showErrorSnackBar(
            'Please select an available pickup date for the selected collector',
          );
          return;
        }
      }
    }

    // Collector selection is now optional - will be auto-assigned if available
    // _selectedCollectorId can be null if no collectors are available

    try {
      _showLoadingDialog();

      // Fetch user info from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        Navigator.of(context).pop();
        _showErrorSnackBar('User data not found');
        return;
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'Unknown';
      final userPhone = userData['phone'] ?? '';

      // Calculate pickup date time - now simplified
      DateTime pickupDateTime;

      if (_selectedScheduleDate != null) {
        // Use the selected scheduled date from collector's schedule
        // Set default time to 9:00 AM if no specific time is selected
        pickupDateTime = DateTime(
          _selectedScheduleDate!.year,
          _selectedScheduleDate!.month,
          _selectedScheduleDate!.day,
          9, // Default to 9:00 AM
          0,
        );
      } else {
        // If no scheduled date, set to tomorrow at 9:00 AM as default
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        pickupDateTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          9, // Default to 9:00 AM
          0,
        );
      }

      // Prepare collector data
      String? collectorId = _selectedCollectorId;
      String? collectorName;

      if (_selectedCollectorId != null) {
        final selectedCollector = _nearbyCollectors.firstWhere(
          (collector) => collector['id'] == _selectedCollectorId,
          orElse: () => {},
        );
        collectorName = selectedCollector['name'] ?? 'Unknown Collector';
      }

      // Calculate total amount
      final totalAmount = _selectedBinCount *
          _pricePerBin *
          (_isEmergencyPickup ? _emergencyMultiplier : 1.0);

      // Save pickup request
      final pickupRequestRef = await FirebaseFirestore.instance
          .collection('pickup_requests')
          .add({
            'userId': widget.userId,
            'userName': userName,
            'userPhone': userPhone,
            'userTown': _townController.text.trim().toLowerCase(),
            'userLatitude': _currentPosition!.latitude,
            'userLongitude': _currentPosition!.longitude,
            'collectorId': collectorId ?? '', // Empty string if no collector
            'collectorName':
                collectorName ?? '', // Empty string if no collector
            'pickupDate': Timestamp.fromDate(pickupDateTime),
            'isPickupToday':
                false, // Always false since we removed today option
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            // Payment and bin information
            'binCount': _selectedBinCount,
            'pricePerBin': _pricePerBin,
            'totalAmount': totalAmount,
            'paymentStatus': 'paid',
            'paymentHeld': true, // Payment is held until completion
            'paymentReleased': false, // Payment not yet released to collector
            // Emergency pickup information
            'isEmergency': _isEmergencyPickup,
            'emergencyMultiplier': _isEmergencyPickup
                ? _emergencyMultiplier
                : 1.0,
          });

      // Create payment history record
      try {
        await PaymentService.createPickupPaymentRecord(
          requestId: pickupRequestRef.id,
          userId: widget.userId,
          amount: totalAmount,
          status: 'pending',
          requestData: {
            'userTown': _townController.text.trim().toLowerCase(),
            'binCount': _selectedBinCount,
            'pricePerBin': _pricePerBin,
            'isEmergency': _isEmergencyPickup,
          },
        );
      } catch (e) {
        print('Error creating payment history record: $e');
      }

      // Create notification for the collector if one is selected
      if (collectorId != null && collectorId.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': collectorId,
            'type': _isEmergencyPickup
                ? 'emergency_pickup_request'
                : 'new_pickup_request',
            'title': _isEmergencyPickup
                ? '🚨 Emergency Pickup Request'
                : '🗑️ New Pickup Request',
            'message': _isEmergencyPickup
                ? '🚨 EMERGENCY: ${userName} has requested an urgent pickup in ${_townController.text.trim()}'
                : '${userName} has requested a pickup in ${_townController.text.trim()}',
            'data': {
              'pickupRequestId': pickupRequestRef.id,
              'userId': widget.userId,
              'userName': userName,
              'userPhone': userPhone,
              'userTown': _townController.text.trim(),
              'pickupDate': Timestamp.fromDate(pickupDateTime),
              'status': 'pending',
              'isEmergency': _isEmergencyPickup,
            },
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('Error creating pickup request notification: $e');
        }
      }

      Navigator.of(context).pop();
      _showSuccessDialog();
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Failed to submit request: ${e.toString()}');
    }
  }

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

  // Handle submit with payment
  Future<void> _handleSubmitWithPayment() async {
    HapticFeedback.mediumImpact();

    // First validate the form
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      _showErrorSnackBar('Please set your location first');
      return;
    }

    // Now process payment
    await _simulatePayment();
  }

  // NEW: Payment simulation method
  Future<void> _simulatePayment() async {
    HapticFeedback.mediumImpact();

    // Show payment processing dialog
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
                  Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Processing Payment...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                "Simulating payment processing",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Close loading dialog
    Navigator.of(context).pop();

    // Show payment success dialog
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
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment of GH₵${(_selectedBinCount * _pricePerBin).toStringAsFixed(2)} has been processed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment will be held and released to the collector upon request completion.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _isPaymentCompleted = true;
                    });

                    // Automatically submit the request after payment
                    await _submitPickupRequest();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final bool hasCollector = _selectedCollectorId != null;

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
                  color: hasCollector
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasCollector ? Icons.check_circle : Icons.schedule,
                  size: 48,
                  color: hasCollector
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasCollector ? 'Success!' : 'Request Queued!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: hasCollector
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasCollector
                    ? 'Your pickup request has been submitted successfully and assigned to a collector. You can track its status in the requests tab.'
                    : 'Your pickup request has been queued successfully. It will be automatically assigned to a collector when one becomes available in your area.',
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
                        Navigator.of(context).pushNamed(
                          '/user-requests',
                          arguments: {'userId': widget.userId},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasCollector
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
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
      _townController.clear();
      _selectedCategories.clear();
      _currentPosition = null;
      _locationStatus = "Location not set";
      _nearbyCollectors.clear();
      _selectedCollectorId = null;
      _selectedScheduleDate = null; // Reset scheduled date
      // Reset payment variables
      _selectedBinCount = 1;
      _isEmergencyPickup = false;
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

                          // // NEW: Pickup Type Selection Card
                          // _buildAnimatedCard(
                          //   delay: 200,
                          //   child: _buildPickupTypeSection(),
                          // ),
                          _buildAnimatedCard(
                            delay: 900,
                            child: _buildCollectorSelectionWithSummary(),
                          ),
                          const SizedBox(height: 16),
                          // Schedule Card (Updated)
                          // _buildAnimatedCard(
                          //   delay: 500,
                          //   child: _buildScheduleSection(),
                          // ),

                          // NEW: Emergency Pickup Card
                          _buildAnimatedCard(
                            delay: 250,
                            child: _buildEmergencyPickupSection(),
                          ),
                          const SizedBox(height: 16),

                          // NEW: Bin Selection and Payment Card
                          _buildAnimatedCard(
                            delay: 300,
                            child: _buildBinSelectionAndPaymentSection(),
                          ),

                          const SizedBox(height: 16),

                          // Location Card
                          _buildAnimatedCard(
                            delay: 700,
                            child: _buildLocationSection(),
                          ),

                          const SizedBox(height: 16),

                          // Collector Selection Card
                          const SizedBox(height: 32),

                          // Submit Button
                          _buildAnimatedCard(
                            delay: 1100,
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
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStyledTextField(
                controller: _townController,
                label: 'Town',
                icon: Icons.location_city_outlined,
                hint: 'Enter your town',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your town';
                  }
                  return null;
                },
              ),
              if (_isLoadingCollectors) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Finding collectors in your town...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Pickup Type Selection Section
  // Widget _buildPickupTypeSection() {
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
  //                 color: Colors.indigo.shade50,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 Icons.today,
  //                 color: Colors.indigo.shade600,
  //                 size: 24,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             const Text(
  //               'When do you need pickup?',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: Color(0xFF2E2E2E),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Choose if you want pickup today or schedule for later',
  //           style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
  //         ),
  //         const SizedBox(height: 20),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: GestureDetector(
  //                 onTap: () {
  //                   HapticFeedback.lightImpact();
  //                   setState(() {
  //                     _isPickupToday = true;
  //                     _selectedDate =
  //                         null; // Clear scheduled date when switching to today
  //                   });
  //                 },
  //                 child: AnimatedContainer(
  //                   duration: const Duration(milliseconds: 300),
  //                   padding: const EdgeInsets.all(20),
  //                   decoration: BoxDecoration(
  //                     color: _isPickupToday
  //                         ? Colors.indigo.shade50
  //                         : Colors.grey.shade50,
  //                     borderRadius: BorderRadius.circular(16),
  //                     border: Border.all(
  //                       color: _isPickupToday
  //                           ? Colors.indigo.shade600
  //                           : Colors.grey.shade300,
  //                       width: _isPickupToday ? 2 : 1,
  //                     ),
  //                   ),
  //                   child: Column(
  //                     children: [
  //                       Icon(
  //                         Icons.today,
  //                         size: 32,
  //                         color: _isPickupToday
  //                             ? Colors.indigo.shade600
  //                             : Colors.grey.shade600,
  //                       ),
  //                       const SizedBox(height: 12),
  //                       Text(
  //                         'Today',
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: _isPickupToday
  //                               ? Colors.indigo.shade700
  //                               : Colors.grey.shade700,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         'Same-day pickup',
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: _isPickupToday
  //                               ? Colors.indigo.shade600
  //                               : Colors.grey.shade600,
  //                         ),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: GestureDetector(
  //                 onTap: () {
  //                   HapticFeedback.lightImpact();
  //                   setState(() {
  //                     _isPickupToday = false;
  //                   });
  //                 },
  //                 child: AnimatedContainer(
  //                   duration: const Duration(milliseconds: 300),
  //                   padding: const EdgeInsets.all(20),
  //                   decoration: BoxDecoration(
  //                     color: !_isPickupToday
  //                         ? Colors.indigo.shade50
  //                         : Colors.grey.shade50,
  //                     borderRadius: BorderRadius.circular(16),
  //                     border: Border.all(
  //                       color: !_isPickupToday
  //                           ? Colors.indigo.shade600
  //                           : Colors.grey.shade300,
  //                       width: !_isPickupToday ? 2 : 1,
  //                     ),
  //                   ),
  //                   child: Column(
  //                     children: [
  //                       Icon(
  //                         Icons.schedule,
  //                         size: 32,
  //                         color: !_isPickupToday
  //                             ? Colors.indigo.shade600
  //                             : Colors.grey.shade600,
  //                       ),
  //                       const SizedBox(height: 12),
  //                       Text(
  //                         'Schedule',
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: !_isPickupToday
  //                               ? Colors.indigo.shade700
  //                               : Colors.grey.shade700,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         'Pick date & time',
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: !_isPickupToday
  //                               ? Colors.indigo.shade600
  //                               : Colors.grey.shade600,
  //                         ),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

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

  // Widget _buildScheduleSection() {
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
  //                 color: Colors.orange.shade50,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 _isPickupToday ? Icons.access_time : Icons.schedule,
  //                 color: Colors.orange.shade600,
  //                 size: 24,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Text(
  //               _isPickupToday ? 'Pick Time for Today' : 'Schedule Pickup',
  //               style: const TextStyle(
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.bold,
  //                 color: Color(0xFF2E2E2E),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           _isPickupToday
  //               ? 'Select what time you want pickup today'
  //               : 'Choose when you want your waste to be collected',
  //           style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
  //         ),
  //         const SizedBox(height: 20),

  //         if (_isPickupToday) ...[
  //           // Show only time selector for today
  //           _buildScheduleButton(
  //             icon: Icons.access_time,
  //             label: _selectedTime == null
  //                 ? 'Select Time for Today'
  //                 : 'Today at ${_selectedTime!.format(context)}',
  //             onTap: _selectTime,
  //             isSelected: _selectedTime != null,
  //             fullWidth: true,
  //           ),
  //         ] else ...[
  //           // Show both date and time selectors for scheduled pickup
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: _buildScheduleButton(
  //                   icon: Icons.calendar_today,
  //                   label: _selectedDate == null
  //                       ? 'Select Date'
  //                       : DateFormat('MMM dd, yyyy').format(_selectedDate!),
  //                   onTap: _selectDate,
  //                   isSelected: _selectedDate != null,
  //                 ),
  //               ),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: _buildScheduleButton(
  //                   icon: Icons.access_time,
  //                   label: _selectedTime == null
  //                       ? 'Select Time'
  //                       : _selectedTime!.format(context),
  //                   onTap: _selectTime,
  //                   isSelected: _selectedTime != null,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],

  //         // Show helpful info
  //         if (_isPickupToday) ...[
  //           const SizedBox(height: 12),
  //           Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: Colors.blue.shade50,
  //               borderRadius: BorderRadius.circular(8),
  //               border: Border.all(color: Colors.blue.shade200),
  //             ),
  //             child: Row(
  //               children: [
  //                 Icon(Icons.info, size: 16, color: Colors.blue.shade600),
  //                 const SizedBox(width: 8),
  //                 Expanded(
  //                   child: Text(
  //                     'Pickup must be at least 30 minutes from now and before 5:00 PM',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: Colors.blue.shade700,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  // ignore: unused_element
  Widget _buildScheduleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: fullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.green.shade600
                          : Colors.grey.shade700,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.green.shade600
                          : Colors.grey.shade700,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
                'Collector Assignment',
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
            'Collectors will be automatically assigned based on availability',
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 48, color: Colors.orange.shade600),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Collectors Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your request will be queued and automatically assigned when a collector becomes available in your area.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Request will be queued',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade800,
                      ),
                    ),
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
                      _onCollectorSelected(collector['id']);
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.purple.shade800
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  collector['phone'] ?? 'No phone',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected
                                        ? Colors.purple.shade600
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Show available dates count
                                if (_collectorSchedules[collector['id']]
                                        ?.isNotEmpty ==
                                    true) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_collectorSchedules[collector['id']]!.length} available dates',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'No scheduled dates',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade600,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_nearbyCollectors.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Schedule Date Selection
            if (_selectedCollectorId != null &&
                _collectorSchedules[_selectedCollectorId]?.isNotEmpty ==
                    true) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Pickup Dates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a date that works for you:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _collectorSchedules[_selectedCollectorId]!.map((
                        date,
                      ) {
                        final isSelected =
                            _selectedScheduleDate?.isAtSameMomentAs(
                              date.copyWith(
                                hour: 0,
                                minute: 0,
                                second: 0,
                                millisecond: 0,
                                microsecond: 0,
                              ),
                            ) ??
                            false;

                        return GestureDetector(
                          onTap: () => _onScheduleDateSelected(date),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade600
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue.shade600
                                    : Colors.blue.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              DateFormat('MMM dd, EEE').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Collector automatically selected. You can change the selection if needed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Add selection summary after collector selection
  Widget _buildCollectorSelectionWithSummary() {
    return Column(
      children: [
        _buildCollectorSection(),
        if (_selectedCollectorId != null) ...[
          const SizedBox(height: 16),
          _buildSelectionSummary(),
        ],
      ],
    );
  }

  Widget _buildEmergencyPickupSection() {
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
                  Icons.emergency,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Emergency Pickup',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Emergency Toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isEmergencyPickup = !_isEmergencyPickup;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isEmergencyPickup
                    ? Colors.red.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isEmergencyPickup
                      ? Colors.red.shade600
                      : Colors.grey.shade300,
                  width: _isEmergencyPickup ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _isEmergencyPickup
                          ? Colors.red.shade600
                          : Colors.transparent,
                      border: Border.all(
                        color: _isEmergencyPickup
                            ? Colors.red.shade600
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _isEmergencyPickup
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark as Emergency Pickup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isEmergencyPickup
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Priority handling with 50% extra charge (GH₵${(_pricePerBin * _emergencyMultiplier).toStringAsFixed(0)} per bin)',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isEmergencyPickup
                                ? Colors.red.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEmergencyPickup)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EMERGENCY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_isEmergencyPickup) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Emergency pickups are prioritized and will be handled as soon as possible. Additional charges apply.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBinSelectionAndPaymentSection() {
    final totalCost =
        _selectedBinCount *
        _pricePerBin *
        (_isEmergencyPickup ? _emergencyMultiplier : 1.0);

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
                  Icons.delete_sweep,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Bin Selection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bin Selection
          Text(
            'How many bins need to be emptied?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Bin Counter
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrease Button
                GestureDetector(
                  onTap: () {
                    if (_selectedBinCount > 1) {
                      setState(() {
                        _selectedBinCount--;
                      });
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedBinCount > 1
                          ? Colors.orange.shade600
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove,
                      color: _selectedBinCount > 1
                          ? Colors.white
                          : Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Bin Count Display
                Column(
                  children: [
                    Text(
                      '$_selectedBinCount',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      'Bin${_selectedBinCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 24),

                // Increase Button
                GestureDetector(
                  onTap: () {
                    if (_selectedBinCount < _maxBinCount) {
                      setState(() {
                        _selectedBinCount++;
                      });
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedBinCount < _maxBinCount
                          ? Colors.orange.shade600
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: _selectedBinCount < _maxBinCount
                          ? Colors.white
                          : Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Cost Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cost',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'GH₵${totalCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rate: GH₵${(_pricePerBin * (_isEmergencyPickup ? _emergencyMultiplier : 1.0)).toStringAsFixed(2)} per bin${_isEmergencyPickup ? ' (Emergency)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '${_selectedBinCount} × GH₵${(_pricePerBin * (_isEmergencyPickup ? _emergencyMultiplier : 1.0)).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final totalCost =
        _selectedBinCount *
        _pricePerBin *
        (_isEmergencyPickup ? _emergencyMultiplier : 1.0);

    return Container(
      width: double.infinity,
      height: 70,
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
        onPressed: _handleSubmitWithPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Request Pickup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pay GH₵${totalCost.toStringAsFixed(2)} • ${_selectedBinCount} bin${_selectedBinCount > 1 ? 's' : ''}${_isEmergencyPickup ? ' • EMERGENCY' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary section showing selected collector and date
  Widget _buildSelectionSummary() {
    if (_selectedCollectorId == null) return const SizedBox.shrink();

    final selectedCollector = _nearbyCollectors.firstWhere(
      (collector) => collector['id'] == _selectedCollectorId,
      orElse: () => {},
    );

    if (selectedCollector.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Selection Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                'Collector: ${selectedCollector['name']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (_selectedScheduleDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Date: ${DateFormat('EEEE, MMM dd, yyyy').format(_selectedScheduleDate!)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Find similar town names to help users with typos or similar names
  List<String> _findSimilarTowns(
    String userTown,
    List<Map<String, dynamic>> allCollectors,
  ) {
    final Set<String> allTowns = {};

    // Collect all unique towns from collectors
    for (final collector in allCollectors) {
      if (collector['town'] != null) {
        allTowns.add(collector['town'].toString().toLowerCase());
      }
    }

    // Find towns that are similar to the user's input
    final List<String> similarTowns = [];
    final userTownLower = userTown.toLowerCase();

    for (final town in allTowns) {
      // Check for exact substring matches
      if (town.contains(userTownLower) || userTownLower.contains(town)) {
        similarTowns.add(town);
      }
      // Check for similar spelling (simple Levenshtein-like distance)
      else if (_calculateSimilarity(userTownLower, town) > 0.7) {
        similarTowns.add(town);
      }
    }

    // Sort by similarity and return top matches
    similarTowns.sort(
      (a, b) => _calculateSimilarity(
        userTownLower,
        b,
      ).compareTo(_calculateSimilarity(userTownLower, a)),
    );

    return similarTowns.take(5).toList();
  }

  // Calculate similarity between two strings (0.0 to 1.0)
  double _calculateSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    // Simple similarity calculation based on common characters
    final chars1 = str1.split('');
    final chars2 = str2.split('');

    int commonChars = 0;
    for (final char in chars1) {
      if (chars2.contains(char)) {
        commonChars++;
      }
    }

    return commonChars / (chars1.length + chars2.length - commonChars);
  }
}
