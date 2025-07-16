// Complete WastePickupFormUpdated with all functionality
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/user_screen/user_request_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' show DateFormat;

class WastePickupFormUpdated extends StatefulWidget {
  final String userId; // Add userId parameter

  const WastePickupFormUpdated({super.key, required this.userId});

  @override
  State<WastePickupFormUpdated> createState() => _WastePickupFormUpdatedState();
}

class _WastePickupFormUpdatedState extends State<WastePickupFormUpdated> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _townController = TextEditingController();

  // Location variables
  Position? _currentPosition;
  bool _isLocationLoading = false;
  String _locationStatus = "Location not set";

  // Date and time variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Category selection
  final List<String> _wasteCategories = [
    'Plastic',
    'Metal',
    'Paper',
    'Glass',
    'Electronic',
    'Organic',
    'Hazardous',
    'Cardboard',
    'Trash',
  ];

  Set<String> _selectedCategories = <String>{};

  // Collectors
  List<Map<String, dynamic>> _nearbyCollectors = [];
  String? _selectedCollectorId;
  bool _isLoadingCollectors = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _townController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _townController.addListener(() {
      final town = _townController.text.trim();
      if (town.isNotEmpty && town.length >= 3) {
        _fetchNearbyCollectors();
      }
    });
  }

  // Date and time selection methods
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Get Current Location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationStatus = "Getting location...";
    });

    try {
      // Check location permission
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus =
            "Location set: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        _isLocationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = "Error: ${e.toString()}";
        _isLocationLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: ${e.toString()}')),
      );
    }
  }

  // Fetch Nearby Collectors
  Future<void> _fetchNearbyCollectors() async {
    setState(() {
      _isLoadingCollectors = true;
      _nearbyCollectors.clear();
      _selectedCollectorId = null;
    });

    try {
      // Get user town from input
      String userTown = _townController.text.trim().toLowerCase();

      if (userTown.isEmpty) {
        throw Exception('Please enter your town to fetch collectors.');
      }

      // Fetch collectors matching the user's town
      QuerySnapshot collectorsSnapshot = await FirebaseFirestore.instance
          .collection('collectors')
          .where('town', isEqualTo: userTown)
          .get();

      List<Map<String, dynamic>> townCollectors = [];

      for (QueryDocumentSnapshot doc in collectorsSnapshot.docs) {
        Map<String, dynamic> collectorData = doc.data() as Map<String, dynamic>;

        townCollectors.add({
          'id': doc.id,
          'name': collectorData['name'] ?? 'Unknown Collector',
          'phone': collectorData['phone'] ?? '',
          'town': collectorData['town'],
        });
      }

      setState(() {
        _nearbyCollectors = townCollectors;
        _isLoadingCollectors = false;
      });

      if (_nearbyCollectors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No collectors found in your town.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingCollectors = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch collectors: ${e.toString()}')),
      );
    }
  }

  // Submit Pickup Request
  Future<void> _submitPickupRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_townController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your town')));
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one waste category'),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup date')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup time')),
      );
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your location first')),
      );
      return;
    }
    if (_selectedCollectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a collector')),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Submitting request..."),
            ],
          ),
        ),
      );

      // Create pickup datetime
      DateTime pickupDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Submit to Firestore with userId
      await FirebaseFirestore.instance.collection('pickup_requests').add({
        'userId': widget.userId, // Add userId to link request to user
        'userName': _nameController.text.trim(),
        'userPhone': _phoneController.text.trim(),
        'userTown': _townController.text.trim(),
        'wasteCategories': _selectedCategories.toList(),
        'userLatitude': _currentPosition!.latitude,
        'userLongitude': _currentPosition!.longitude,
        'collectorId': _selectedCollectorId,
        'pickupDate': Timestamp.fromDate(pickupDateTime),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog with option to view requests
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: const Text(
            'Your pickup request has been submitted successfully. You can track its status in the requests tab.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UserRequestsScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Text('View Requests'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: ${e.toString()}')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _phoneController.clear();
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
    return SingleChildScrollView(
      //backgroundColor: const Color(0xFFF8FFFE),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Information
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _townController,
                        decoration: const InputDecoration(
                          labelText: 'Town',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                          hintText: 'Enter your town or city',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your town or city';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Waste Categories Selection
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Waste Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: _wasteCategories.map((category) {
                          return FilterChip(
                            label: Text(category),
                            selected: _selectedCategories.contains(category),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date and Time Selection
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Schedule',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectDate(),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_selectedDate!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectTime(),
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                _selectedTime == null
                                    ? 'Select Time'
                                    : _selectedTime!.format(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Location
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Your Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_locationStatus),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLocationLoading
                            ? null
                            : _getCurrentLocation,
                        icon: _isLocationLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.location_on),
                        label: Text(
                          _isLocationLoading
                              ? 'Getting Location...'
                              : 'Get Current Location',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Select Collector
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Collector',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingCollectors)
                        const Center(child: CircularProgressIndicator())
                      else
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Collector',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_pin),
                          ),
                          value: _selectedCollectorId,
                          items: _nearbyCollectors.map((collector) {
                            return DropdownMenuItem<String>(
                              value: collector['id'],
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${collector['name']}\n',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${collector['town']}\n',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    TextSpan(
                                      text: collector['phone'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCollectorId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a collector';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitPickupRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Submit Pickup Request',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
