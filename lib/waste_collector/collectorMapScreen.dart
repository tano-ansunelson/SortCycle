// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:math' as math;
// import 'package:url_launcher/url_launcher.dart';

// class CollectorMapScreen extends StatefulWidget {
//   final String collectorId;
//   const CollectorMapScreen({required this.collectorId, super.key});

//   @override
//   State<CollectorMapScreen> createState() => _CollectorMapScreenState();
// }

// class _CollectorMapScreenState extends State<CollectorMapScreen> {
//   late GoogleMapController _mapController;
//   Set<Marker> _markers = {};
//   Set<Polyline> _polylines = {};
//   LatLng _initialPosition = const LatLng(6.6730, -1.5715); // Default to KNUST
//   bool _isLoading = true;
//   String? _errorMessage;
//   String? _nearestLocationId;
//   double? _nearestDistance;

//   @override
//   void initState() {
//     super.initState();
//     _initializeMap();
//   }

//   Future<void> _initializeMap() async {
//     try {
//       await Future.wait([_getCurrentLocation(), _loadAcceptedRequests()]);
//       // After loading everything, find and draw route to nearest location
//       await _drawRouteToNearestLocation();
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to load map data: $e';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     try {
//       // Check if location services are enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Location services are disabled. Please enable location services.',
//               ),
//               backgroundColor: Colors.orange,
//               action: SnackBarAction(
//                 label: 'Settings',
//                 onPressed: () => Geolocator.openLocationSettings(),
//               ),
//             ),
//           );
//         }
//         // Use default location
//         _addCollectorMarker();
//         return;
//       }

//       // Check location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           throw Exception('Location permissions are denied');
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Location permissions are permanently denied. Please enable in app settings.',
//               ),
//               backgroundColor: Colors.red,
//               action: SnackBarAction(
//                 label: 'Settings',
//                 onPressed: () => Geolocator.openAppSettings(),
//               ),
//             ),
//           );
//         }
//         _addCollectorMarker();
//         return;
//       }

//       // Show loading indicator
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Row(
//               children: [
//                 SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//                 SizedBox(width: 16),
//                 Text('Getting your location...'),
//               ],
//             ),
//             duration: Duration(seconds: 5),
//           ),
//         );
//       }

//       // Try to get last known position first (faster)
//       Position? lastPosition;
//       try {
//         lastPosition = await Geolocator.getLastKnownPosition();
//         if (lastPosition != null) {
//           setState(() {
//             _initialPosition = LatLng(
//               lastPosition!.latitude,
//               lastPosition.longitude,
//             );
//           });
//           _addCollectorMarker();
//           print(
//             'Using last known location: ${lastPosition.latitude}, ${lastPosition.longitude}',
//           );
//         }
//       } catch (e) {
//         print('Could not get last known position: $e');
//       }

//       // Get current high accuracy location
//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 30), // Increased timeout
//       );

//       // Verify the position is reasonable (not 0,0 or other invalid coordinates)
//       if (position.latitude == 0.0 && position.longitude == 0.0) {
//         throw Exception('Invalid location coordinates received');
//       }

//       setState(() {
//         _initialPosition = LatLng(position.latitude, position.longitude);
//       });

//       print(
//         'Current location obtained: ${position.latitude}, ${position.longitude}',
//       );
//       print('Accuracy: ${position.accuracy} meters');

//       _addCollectorMarker();

//       // Move camera to new location if significantly different from last known
//       if (lastPosition == null ||
//           Geolocator.distanceBetween(
//                 lastPosition.latitude,
//                 lastPosition.longitude,
//                 position.latitude,
//                 position.longitude,
//               ) >
//               100) {
//         _mapController.animateCamera(
//           CameraUpdate.newLatLngZoom(_initialPosition, 16),
//         );
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Location updated (±${position.accuracy.toInt()}m accuracy)',
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error getting location: $e');
//       // Show error to user
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Location error: ${e.toString().replaceAll('Exception: ', '')}',
//             ),
//             backgroundColor: Colors.orange,
//             duration: const Duration(seconds: 4),
//             action: SnackBarAction(
//               label: 'Retry',
//               onPressed: _getCurrentLocation,
//             ),
//           ),
//         );
//       }
//       // Keep default location if current location fails
//       _addCollectorMarker();
//     }
//   }

//   void _addCollectorMarker() {
//     setState(() {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('collector'),
//           position: _initialPosition,
//           infoWindow: const InfoWindow(
//             title: 'Your Location',
//             snippet: 'Waste Collector',
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//         ),
//       );
//     });
//   }

//   Future<void> _loadAcceptedRequests() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('pickup_requests')
//           .where('status', whereIn: ['in_progress', 'accepted'])
//           .where('collectorId', isEqualTo: widget.collectorId)
//           .get();

//       if (snapshot.docs.isEmpty) {
//         print(
//           'No accepted pickup requests found for collector: ${widget.collectorId}',
//         );
//         return;
//       }

//       print('Found ${snapshot.docs.length} accepted requests');

//       Set<Marker> requestMarkers = {};
//       int validRequests = 0;
//       int invalidRequests = 0;
//       _markers.removeWhere((m) => m.markerId.value != 'collector');

//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         final userLatitude = data['userLatitude'];
//         final userLongitude = data['userLongitude'];

//         // Handle potential null values
//         if (userLatitude == null || userLongitude == null) {
//           print(
//             'Warning: Request ${doc.id} has no location data - userLatitude: $userLatitude, userLongitude: $userLongitude',
//           );
//           invalidRequests++;
//           continue;
//         }

//         // Convert to double if needed
//         double lat, lng;
//         try {
//           lat = userLatitude is double
//               ? userLatitude
//               : double.parse(userLatitude.toString());
//           lng = userLongitude is double
//               ? userLongitude
//               : double.parse(userLongitude.toString());

//           // Validate coordinates are reasonable
//           if (lat.abs() > 90 || lng.abs() > 180) {
//             print(
//               'Warning: Request ${doc.id} has invalid coordinates - lat: $lat, lng: $lng',
//             );
//             invalidRequests++;
//             continue;
//           }

//           validRequests++;
//         } catch (e) {
//           print('Error parsing coordinates for request ${doc.id}: $e');
//           invalidRequests++;
//           continue;
//         }

//         final marker = Marker(
//           markerId: MarkerId(doc.id),
//           position: LatLng(lat, lng),
//           infoWindow: InfoWindow(
//             title: data['userName'] ?? 'Pickup Request',
//             snippet:
//                 '${_formatWasteCategories(data['wasteCategories'])} - Tap for details',
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueGreen,
//           ),
//           onTap: () => _showRequestDetails(doc.id, data),
//         );

//         requestMarkers.add(marker);
//       }

//       setState(() {
//         _markers = {..._markers, ...requestMarkers}; // create a new Set
//       });

//       print(
//         'Added $validRequests valid markers, skipped $invalidRequests invalid requests',
//       );

//       // Show summary to user
//       if (mounted) {
//         String message = 'Loaded $validRequests pickup requests';
//         if (invalidRequests > 0) {
//           message += ' ($invalidRequests requests have invalid location data)';
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: invalidRequests > 0 ? Colors.orange : Colors.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }

//       // Move camera to show all markers if requests exist
//       if (requestMarkers.isNotEmpty && mounted) {
//         Future.delayed(const Duration(milliseconds: 1000), () {
//           if (mounted) _fitMarkersInView();
//         });
//       }
//     } catch (e) {
//       throw Exception('Failed to load pickup requests: $e');
//     }
//   }

//   // NEW METHOD: Find and draw route to nearest pickup location
//   Future<void> _drawRouteToNearestLocation() async {
//     if (_markers.length <= 1) return; // Only collector marker exists

//     double nearestDistance = double.infinity;
//     LatLng? nearestLocation;
//     String? nearestLocationId;
//     String? nearestLocationName;

//     // Find the nearest pickup location
//     for (final marker in _markers) {
//       if (marker.markerId.value == 'collector') continue;

//       final distance = Geolocator.distanceBetween(
//         _initialPosition.latitude,
//         _initialPosition.longitude,
//         marker.position.latitude,
//         marker.position.longitude,
//       );

//       if (distance < nearestDistance) {
//         nearestDistance = distance;
//         nearestLocation = marker.position;
//         nearestLocationId = marker.markerId.value;
//         nearestLocationName = marker.infoWindow.title;
//       }
//     }

//     if (nearestLocation != null && nearestLocationId != null) {
//       // Update nearest location info
//       _nearestLocationId = nearestLocationId;
//       _nearestDistance = nearestDistance;

//       // Create route polyline
//       await _createRoutePolyline(_initialPosition, nearestLocation);

//       // Update the nearest marker to make it stand out
//       _highlightNearestMarker(nearestLocationId);

//       // Show info to user
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Route to nearest pickup: ${nearestLocationName ?? 'Unknown'} '
//               '(${(nearestDistance / 1000).toStringAsFixed(2)} km away)',
//             ),
//             backgroundColor: Colors.blue,
//             duration: const Duration(seconds: 4),
//             action: SnackBarAction(
//               label: 'Navigate',
//               onPressed: () => _navigateToNearestLocation(),
//             ),
//           ),
//         );
//       }
//     }
//   }

//   // NEW METHOD: Create route polyline with waypoints for better visualization
//   Future<void> _createRoutePolyline(LatLng start, LatLng end) async {
//     // Clear existing polylines
//     setState(() {
//       _polylines.clear();
//     });

//     // Create a simple straight line route (you can enhance this with actual routing API)
//     final List<LatLng> routePoints = [start, end];

//     // For better visualization, add intermediate points for curved route
//     final List<LatLng> enhancedRoute = _createCurvedRoute(start, end);

//     final Polyline route = Polyline(
//       polylineId: const PolylineId('nearest_route'),
//       points: enhancedRoute,
//       color: Colors.blue,
//       width: 5,
//       patterns: [PatternItem.dash(20), PatternItem.gap(10)],
//       startCap: Cap.roundCap,
//       endCap: Cap.roundCap,
//     );

//     // Add a thicker background line for better visibility
//     final Polyline routeBackground = Polyline(
//       polylineId: const PolylineId('nearest_route_bg'),
//       points: enhancedRoute,
//       color: Colors.white,
//       width: 7,
//     );

//     setState(() {
//       _polylines.addAll([routeBackground, route]);
//     });
//   }

//   // NEW METHOD: Create a curved route for better visualization
//   List<LatLng> _createCurvedRoute(LatLng start, LatLng end) {
//     List<LatLng> points = [];
//     points.add(start);

//     // Add intermediate points for a slight curve
//     final midLat = (start.latitude + end.latitude) / 2;
//     final midLng = (start.longitude + end.longitude) / 2;

//     // Add slight offset for curve effect
//     final offset = 0.001; // Adjust this value for more/less curve
//     final curvePoint = LatLng(midLat + offset, midLng + offset);

//     points.add(curvePoint);
//     points.add(end);

//     return points;
//   }

//   // NEW METHOD: Highlight the nearest marker
//   void _highlightNearestMarker(String markerId) {
//     setState(() {
//       _markers = _markers.map((marker) {
//         if (marker.markerId.value == markerId) {
//           // Create a highlighted version of the nearest marker
//           return marker.copyWith(
//             iconParam: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueOrange, // Different color for nearest
//             ),
//             infoWindowParam: marker.infoWindow.copyWith(
//               snippetParam: '${marker.infoWindow.snippet} - NEAREST',
//             ),
//           );
//         }
//         return marker;
//       }).toSet();
//     });
//   }

//   // NEW METHOD: Quick navigation to nearest location
//   void _navigateToNearestLocation() async {
//     if (_nearestLocationId == null) return;

//     // Find the nearest marker
//     final nearestMarker = _markers.firstWhere(
//       (marker) => marker.markerId.value == _nearestLocationId,
//     );

//     final lat = nearestMarker.position.latitude;
//     final lng = nearestMarker.position.longitude;
//     final name = nearestMarker.infoWindow.title ?? 'Nearest Pickup';

//     // Show quick navigation options
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.near_me, color: Colors.orange),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Navigate to Nearest: $name',
//                     style: Theme.of(context).textTheme.titleLarge,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Distance: ${(_nearestDistance! / 1000).toStringAsFixed(2)} km',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () => _openInGoogleMaps(lat, lng, name),
//                   icon: const Icon(Icons.map),
//                   label: const Text('Google Maps'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () => _openInWaze(lat, lng),
//                   icon: const Icon(Icons.navigation),
//                   label: const Text('Waze'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showRequestDetails(String requestId, Map<String, dynamic> data) {
//     final isNearest = requestId == _nearestLocationId;

//     showBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 if (isNearest) ...[
//                   const Icon(Icons.near_me, color: Colors.orange),
//                   const SizedBox(width: 8),
//                 ],
//                 Expanded(
//                   child: Text(
//                     data['userName'] ?? 'Pickup Request',
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                 ),
//               ],
//             ),
//             if (isNearest) ...[
//               const SizedBox(height: 4),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   'NEAREST LOCATION (${(_nearestDistance! / 1000).toStringAsFixed(2)} km)',
//                   style: const TextStyle(
//                     color: Colors.orange,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 const Icon(Icons.delete_outline),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Waste: ${_formatWasteCategories(data['wasteCategories'])}',
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 const Icon(Icons.location_on),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Location: ${data['userTown'] ?? 'Not specified'}',
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 const Icon(Icons.phone),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Contact: ${data['userPhone'] ?? 'Not provided'}',
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 const Icon(Icons.schedule),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Pickup: ${_formatPickupDate(data['pickupDate'])}',
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 const Icon(Icons.info_outline),
//                 const SizedBox(width: 8),
//                 Expanded(child: Text('Status: ${data['status'] ?? 'Unknown'}')),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () => _navigateToLocation(requestId, data),
//                   icon: const Icon(Icons.directions),
//                   label: const Text('Navigate'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () => _markAsCompleted(requestId),
//                   icon: const Icon(Icons.check_circle),
//                   label: const Text('Complete'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () => _markAsInProgress(requestId),
//                   icon: const Icon(Icons.play_arrow),
//                   label: const Text('Start'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'Unknown';
//     if (timestamp is Timestamp) {
//       final date = timestamp.toDate();
//       return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//     }
//     return timestamp.toString();
//   }

//   String _formatWasteCategories(dynamic categories) {
//     if (categories == null) return 'Unknown';

//     if (categories is List) {
//       return categories.join(', ');
//     }

//     try {
//       // Try to parse if it's a string like "[Plastic, Glass]"
//       final String str = categories.toString();
//       return str
//           .replaceAll('[', '')
//           .replaceAll(']', '')
//           .split(',')
//           .map((e) => e.trim())
//           .join(', ');
//     } catch (e) {
//       return categories.toString();
//     }
//   }

//   String _formatPickupDate(dynamic timestamp) {
//     if (timestamp == null) return 'Not scheduled';
//     if (timestamp is Timestamp) {
//       final date = timestamp.toDate();
//       final now = DateTime.now();
//       final today = DateTime(now.year, now.month, now.day);
//       final pickupDay = DateTime(date.year, date.month, date.day);

//       if (pickupDay == today) {
//         return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//       } else if (pickupDay == today.add(const Duration(days: 1))) {
//         return 'Tomorrow at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//       } else {
//         return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//       }
//     }
//     return timestamp.toString();
//   }

//   void _navigateToLocation(String requestId, Map<String, dynamic> data) async {
//     Navigator.pop(context); // Close bottom sheet

//     final userLatitude = data['userLatitude'];
//     final userLongitude = data['userLongitude'];

//     if (userLatitude == null || userLongitude == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Location data not available for navigation'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     // Convert to double if needed
//     double lat, lng;
//     try {
//       lat = userLatitude is double
//           ? userLatitude
//           : double.parse(userLatitude.toString());
//       lng = userLongitude is double
//           ? userLongitude
//           : double.parse(userLongitude.toString());
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Invalid location coordinates'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final String name = data['name'] ?? 'Pickup Location';

//     // Show navigation options
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Navigate to $name',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: const Icon(Icons.map, color: Colors.blue),
//               title: const Text('Google Maps'),
//               subtitle: const Text('Open in Google Maps app'),
//               onTap: () => _openInGoogleMaps(lat, lng, name),
//             ),
//             ListTile(
//               leading: const Icon(Icons.navigation, color: Colors.green),
//               title: const Text('Waze'),
//               subtitle: const Text('Open in Waze app'),
//               onTap: () => _openInWaze(lat, lng),
//             ),
//             ListTile(
//               leading: const Icon(Icons.directions, color: Colors.orange),
//               title: const Text('Apple Maps'),
//               subtitle: const Text('Open in Apple Maps (iOS only)'),
//               onTap: () => _openInAppleMaps(lat, lng, name),
//             ),
//             ListTile(
//               leading: const Icon(Icons.route, color: Colors.purple),
//               title: const Text('Show Route on Map'),
//               subtitle: const Text('Display route in this app'),
//               onTap: () => _showRouteOnMap(lat, lng),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _openInGoogleMaps(double lat, double lng, String name) async {
//     Navigator.pop(context);
//     final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
//     _openUrl(url);
//   }

//   void _openInWaze(double lat, double lng) async {
//     Navigator.pop(context);
//     final url = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
//     _openUrl(url);
//   }

//   void _openInAppleMaps(double lat, double lng, String name) async {
//     Navigator.pop(context);
//     final url = 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
//     _openUrl(url);
//   }

//   void _showRouteOnMap(double lat, double lng) async {
//     Navigator.pop(context);

//     // Create a polyline from current location to destination
//     final List<LatLng> routePoints = [_initialPosition, LatLng(lat, lng)];

//     final Polyline route = Polyline(
//       polylineId: const PolylineId('route'),
//       points: routePoints,
//       color: Colors.blue,
//       width: 5,
//       patterns: [PatternItem.dash(10), PatternItem.gap(5)],
//     );

//     setState(() {
//       _polylines.clear();
//       _polylines.add(route);
//     });

//     // Calculate bounds to show both points
//     final bounds = LatLngBounds(
//       southwest: LatLng(
//         math.min(_initialPosition.latitude, lat),
//         math.min(_initialPosition.longitude, lng),
//       ),
//       northeast: LatLng(
//         math.max(_initialPosition.latitude, lat),
//         math.max(_initialPosition.longitude, lng),
//       ),
//     );

//     _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));

//     // Calculate distance
//     final distance = Geolocator.distanceBetween(
//       _initialPosition.latitude,
//       _initialPosition.longitude,
//       lat,
//       lng,
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Route shown. Distance: ${(distance / 1000).toStringAsFixed(2)} km',
//         ),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   Future<void> _openUrl(String url) async {
//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
//     }
//   }

//   Future<void> _markAsInProgress(String requestId) async {
//     try {
//       Navigator.pop(context); // Close bottom sheet

//       await FirebaseFirestore.instance
//           .collection('pickup_requests')
//           .doc(requestId)
//           .update({
//             'status': 'in_progress',
//             'startedAt': FieldValue.serverTimestamp(),
//           });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Pickup marked as in progress!'),
//             backgroundColor: Colors.blue,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error updating pickup: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _markAsCompleted(String requestId) async {
//     try {
//       Navigator.pop(context); // Close bottom sheet

//       // Show confirmation dialog
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Mark as Completed'),
//           content: const Text(
//             'Are you sure you want to mark this pickup as completed?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Complete'),
//             ),
//           ],
//         ),
//       );

//       if (confirmed == true) {
//         await FirebaseFirestore.instance
//             .collection('pickup_requests')
//             .doc(requestId)
//             .update({
//               'status': 'completed',
//               'completedAt': FieldValue.serverTimestamp(),
//             });

//         // Remove marker from map
//         setState(() {
//           _markers.removeWhere((marker) => marker.markerId.value == requestId);
//         });

//         // If this was the nearest location, recalculate route to next nearest
//         if (requestId == _nearestLocationId) {
//           await _drawRouteToNearestLocation();
//         }

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Pickup marked as completed!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error completing pickup: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _fitMarkersInView() {
//     if (_markers.length <= 1) return;

//     final bounds = _calculateBounds(_markers);
//     _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
//   }

//   LatLngBounds _calculateBounds(Set<Marker> markers) {
//     double minLat = markers.first.position.latitude;
//     double maxLat = markers.first.position.latitude;
//     double minLng = markers.first.position.longitude;
//     double maxLng = markers.first.position.longitude;

//     for (final marker in markers) {
//       minLat = math.min(minLat, marker.position.latitude);
//       maxLat = math.max(maxLat, marker.position.latitude);
//       minLng = math.min(minLng, marker.position.longitude);
//       maxLng = math.max(maxLng, marker.position.longitude);
//     }

//     return LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pickup Routes'),
//         actions: [
//           if (_nearestLocationId != null)
//             IconButton(
//               icon: const Icon(Icons.near_me),
//               tooltip: 'Navigate to nearest',
//               onPressed: _navigateToNearestLocation,
//             ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               setState(() {
//                 _markers.clear();
//                 _polylines.clear();
//                 _isLoading = true;
//                 _errorMessage = null;
//                 _nearestLocationId = null;
//                 _nearestDistance = null;
//               });
//               _initializeMap();
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text('Loading map data...'),
//                 ],
//               ),
//             )
//           : _errorMessage != null
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error_outline, size: 48, color: Colors.red),
//                   const SizedBox(height: 16),
//                   Text(
//                     _errorMessage!,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.red),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         _errorMessage = null;
//                         _isLoading = true;
//                       });
//                       _initializeMap();
//                     },
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             )
//           : Stack(
//               children: [
//                 GoogleMap(
//                   initialCameraPosition: CameraPosition(
//                     target: _initialPosition,
//                     zoom: 14,
//                   ),
//                   markers: _markers,
//                   polylines: _polylines,
//                   onMapCreated: (controller) {
//                     _mapController = controller;
//                     if (_markers.length > 1) {
//                       Future.delayed(const Duration(milliseconds: 500), () {
//                         _fitMarkersInView();
//                       });
//                     }
//                   },
//                   myLocationEnabled: true,
//                   myLocationButtonEnabled: true,
//                   zoomControlsEnabled: true,
//                   compassEnabled: true,
//                   mapToolbarEnabled: true,
//                 ),
//                 // Nearest location info card
//                 if (_nearestLocationId != null && _nearestDistance != null)
//                   Positioned(
//                     top: 16,
//                     left: 16,
//                     right: 16,
//                     child: Card(
//                       elevation: 4,
//                       child: Padding(
//                         padding: const EdgeInsets.all(12),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.near_me, color: Colors.orange),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   const Text(
//                                     'Next Pickup',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                   Text(
//                                     '${(_nearestDistance! / 1000).toStringAsFixed(2)} km away',
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.directions),
//                               onPressed: _navigateToNearestLocation,
//                               tooltip: 'Navigate',
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           if (_nearestLocationId != null)
//             FloatingActionButton(
//               heroTag: "navigate",
//               mini: true,
//               backgroundColor: Colors.orange,
//               onPressed: _navigateToNearestLocation,
//               child: const Icon(Icons.navigation, color: Colors.white),
//             ),
//           const SizedBox(height: 8),
//           FloatingActionButton(
//             heroTag: "center",
//             mini: true,
//             onPressed: () {
//               _mapController.animateCamera(
//                 CameraUpdate.newLatLngZoom(_initialPosition, 16),
//               );
//             },
//             child: const Icon(Icons.my_location),
//           ),
//           const SizedBox(height: 8),
//           FloatingActionButton(
//             heroTag: "refresh",
//             onPressed: () {
//               setState(() {
//                 _markers.clear();
//                 _polylines.clear();
//                 _isLoading = true;
//                 _nearestLocationId = null;
//                 _nearestDistance = null;
//               });
//               _initializeMap();
//             },
//             child: const Icon(Icons.refresh),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CollectorMapScreen extends StatefulWidget {
  final String collectorId;
  const CollectorMapScreen({required this.collectorId, super.key});

  @override
  State<CollectorMapScreen> createState() => _CollectorMapScreenState();
}

class _CollectorMapScreenState extends State<CollectorMapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _initialPosition = const LatLng(6.6730, -1.5715); // Default to KNUST
  bool _isLoading = true;
  String? _errorMessage;
  String? _nearestLocationId;
  double? _nearestDistance;

  // Add your Google Maps API key here
  static const String _googleMapsApiKey =
      'AIzaSyDfV-BwmObibrIHDQB4cRuE53BDvspD9Aw';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await Future.wait([_getCurrentLocation(), _loadAcceptedRequests()]);
      // After loading everything, find and draw route to nearest location
      await _drawRouteToNearestLocation();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load map data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location services are disabled. Please enable location services.',
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        // Use default location
        _addCollectorMarker();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location permissions are permanently denied. Please enable in app settings.',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        _addCollectorMarker();
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Getting your location...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Try to get last known position first (faster)
      Position? lastPosition;
      try {
        lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          setState(() {
            _initialPosition = LatLng(
              lastPosition!.latitude,
              lastPosition.longitude,
            );
          });
          _addCollectorMarker();
          print(
            'Using last known location: ${lastPosition.latitude}, ${lastPosition.longitude}',
          );
        }
      } catch (e) {
        print('Could not get last known position: $e');
      }

      // Get current high accuracy location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30), // Increased timeout
      );

      // Verify the position is reasonable (not 0,0 or other invalid coordinates)
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        throw Exception('Invalid location coordinates received');
      }

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
      });

      print(
        'Current location obtained: ${position.latitude}, ${position.longitude}',
      );
      print('Accuracy: ${position.accuracy} meters');

      _addCollectorMarker();

      // Move camera to new location if significantly different from last known
      if (lastPosition == null ||
          Geolocator.distanceBetween(
                lastPosition.latitude,
                lastPosition.longitude,
                position.latitude,
                position.longitude,
              ) >
              100) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_initialPosition, 16),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location updated (±${position.accuracy.toInt()}m accuracy)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
      // Keep default location if current location fails
      _addCollectorMarker();
    }
  }

  void _addCollectorMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('collector'),
          position: _initialPosition,
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Waste Collector',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  Future<void> _loadAcceptedRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('status', whereIn: ['in_progress', 'accepted'])
          .where('collectorId', isEqualTo: widget.collectorId)
          .get();

      if (snapshot.docs.isEmpty) {
        print(
          'No accepted pickup requests found for collector: ${widget.collectorId}',
        );
        return;
      }

      print('Found ${snapshot.docs.length} accepted requests');

      Set<Marker> requestMarkers = {};
      int validRequests = 0;
      int invalidRequests = 0;
      _markers.removeWhere((m) => m.markerId.value != 'collector');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userLatitude = data['userLatitude'];
        final userLongitude = data['userLongitude'];

        // Handle potential null values
        if (userLatitude == null || userLongitude == null) {
          print(
            'Warning: Request ${doc.id} has no location data - userLatitude: $userLatitude, userLongitude: $userLongitude',
          );
          invalidRequests++;
          continue;
        }

        // Convert to double if needed
        double lat, lng;
        try {
          lat = userLatitude is double
              ? userLatitude
              : double.parse(userLatitude.toString());
          lng = userLongitude is double
              ? userLongitude
              : double.parse(userLongitude.toString());

          // Validate coordinates are reasonable
          if (lat.abs() > 90 || lng.abs() > 180) {
            print(
              'Warning: Request ${doc.id} has invalid coordinates - lat: $lat, lng: $lng',
            );
            invalidRequests++;
            continue;
          }

          validRequests++;
        } catch (e) {
          print('Error parsing coordinates for request ${doc.id}: $e');
          invalidRequests++;
          continue;
        }

        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: data['userName'] ?? 'Pickup Request',
            snippet:
                '${_formatWasteCategories(data['wasteCategories'])} - Tap for details',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          onTap: () => _showRequestDetails(doc.id, data),
        );

        requestMarkers.add(marker);
      }

      setState(() {
        _markers = {..._markers, ...requestMarkers}; // create a new Set
      });

      print(
        'Added $validRequests valid markers, skipped $invalidRequests invalid requests',
      );

      // Show summary to user
      if (mounted) {
        String message = 'Loaded $validRequests pickup requests';
        if (invalidRequests > 0) {
          message += ' ($invalidRequests requests have invalid location data)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: invalidRequests > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Move camera to show all markers if requests exist
      if (requestMarkers.isNotEmpty && mounted) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _fitMarkersInView();
        });
      }
    } catch (e) {
      throw Exception('Failed to load pickup requests: $e');
    }
  }

  // NEW METHOD: Find and draw route to nearest pickup location with real road routing
  Future<void> _drawRouteToNearestLocation() async {
    if (_markers.length <= 1) return; // Only collector marker exists

    double nearestDistance = double.infinity;
    LatLng? nearestLocation;
    String? nearestLocationId;
    String? nearestLocationName;

    // Find the nearest pickup location
    for (final marker in _markers) {
      if (marker.markerId.value == 'collector') continue;

      final distance = Geolocator.distanceBetween(
        _initialPosition.latitude,
        _initialPosition.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestLocation = marker.position;
        nearestLocationId = marker.markerId.value;
        nearestLocationName = marker.infoWindow.title;
      }
    }

    if (nearestLocation != null && nearestLocationId != null) {
      // Update nearest location info
      _nearestLocationId = nearestLocationId;
      _nearestDistance = nearestDistance;

      // Get real route from Google Directions API
      await _getDirectionsRoute(_initialPosition, nearestLocation);

      // Update the nearest marker to make it stand out
      _highlightNearestMarker(nearestLocationId);

      // Show info to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Route to nearest pickup: ${nearestLocationName ?? 'Unknown'} '
              '(${(nearestDistance / 1000).toStringAsFixed(2)} km away)',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Navigate',
              onPressed: () => _navigateToNearestLocation(),
            ),
          ),
        );
      }
    }
  }

  // NEW METHOD: Get directions from Google Directions API
  Future<void> _getDirectionsRoute(LatLng origin, LatLng destination) async {
    if (_googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      // Fallback to simple route if API key not configured
      _createSimpleRoute(origin, destination);
      return;
    }

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=driving&'
          'key=$_googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];
          final List<LatLng> routeCoords = _decodePolyline(polylinePoints);

          // Get route info
          final duration = route['legs'][0]['duration']['text'];
          final distance = route['legs'][0]['distance']['text'];

          _createRoutePolyline(routeCoords, duration, distance);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Route loaded: $distance, $duration'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('Directions API error: ${data['status']}');
          _createSimpleRoute(origin, destination);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        _createSimpleRoute(origin, destination);
      }
    } catch (e) {
      print('Error getting directions: $e');
      _createSimpleRoute(origin, destination);
    }
  }

  // NEW METHOD: Decode Google's polyline encoding
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // NEW METHOD: Create route polyline with real road coordinates
  void _createRoutePolyline(
    List<LatLng> routeCoords,
    String duration,
    String distance,
  ) {
    setState(() {
      _polylines.clear();
    });

    // Main route line
    final Polyline route = Polyline(
      polylineId: const PolylineId('nearest_route'),
      points: routeCoords,
      color: Colors.blue,
      width: 6,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );

    // Background route line for better visibility
    final Polyline routeBackground = Polyline(
      polylineId: const PolylineId('nearest_route_bg'),
      points: routeCoords,
      color: Colors.white,
      width: 8,
    );

    setState(() {
      _polylines.addAll([routeBackground, route]);
    });

    // Fit the route in view
    if (routeCoords.isNotEmpty) {
      _fitRouteInView(routeCoords);
    }
  }

  // NEW METHOD: Create simple fallback route when API is not available
  void _createSimpleRoute(LatLng start, LatLng end) {
    final List<LatLng> routePoints = [start, end];

    final Polyline route = Polyline(
      polylineId: const PolylineId('nearest_route'),
      points: routePoints,
      color: Colors.blue,
      width: 5,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    final Polyline routeBackground = Polyline(
      polylineId: const PolylineId('nearest_route_bg'),
      points: routePoints,
      color: Colors.white,
      width: 7,
    );

    setState(() {
      _polylines.clear();
      _polylines.addAll([routeBackground, route]);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Using direct route (configure API key for road routing)',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // NEW METHOD: Fit route in camera view
  void _fitRouteInView(List<LatLng> routeCoords) {
    if (routeCoords.isEmpty) return;

    double minLat = routeCoords.first.latitude;
    double maxLat = routeCoords.first.latitude;
    double minLng = routeCoords.first.longitude;
    double maxLng = routeCoords.first.longitude;

    for (final point in routeCoords) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  // NEW METHOD: Highlight the nearest marker
  void _highlightNearestMarker(String markerId) {
    setState(() {
      _markers = _markers.map((marker) {
        if (marker.markerId.value == markerId) {
          // Create a highlighted version of the nearest marker
          return marker.copyWith(
            iconParam: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange, // Different color for nearest
            ),
            infoWindowParam: marker.infoWindow.copyWith(
              snippetParam: '${marker.infoWindow.snippet} - NEAREST',
            ),
          );
        }
        return marker;
      }).toSet();
    });
  }

  // NEW METHOD: Quick navigation to nearest location
  void _navigateToNearestLocation() async {
    if (_nearestLocationId == null) return;

    // Find the nearest marker
    final nearestMarker = _markers.firstWhere(
      (marker) => marker.markerId.value == _nearestLocationId,
    );

    final lat = nearestMarker.position.latitude;
    final lng = nearestMarker.position.longitude;
    final name = nearestMarker.infoWindow.title ?? 'Nearest Pickup';

    // Show quick navigation options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.near_me, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Navigate to Nearest: $name',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Distance: ${(_nearestDistance! / 1000).toStringAsFixed(2)} km',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openInGoogleMaps(lat, lng, name),
                  icon: const Icon(Icons.map),
                  label: const Text('Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openInWaze(lat, lng),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Waze'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(String requestId, Map<String, dynamic> data) {
    final isNearest = requestId == _nearestLocationId;

    showBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isNearest) ...[
                  const Icon(Icons.near_me, color: Colors.orange),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    data['userName'] ?? 'Pickup Request',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            if (isNearest) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'NEAREST LOCATION (${(_nearestDistance! / 1000).toStringAsFixed(2)} km)',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.delete_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Waste: ${_formatWasteCategories(data['wasteCategories'])}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location: ${data['userTown'] ?? 'Not specified'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contact: ${data['userPhone'] ?? 'Not provided'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup: ${_formatPickupDate(data['pickupDate'])}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(child: Text('Status: ${data['status'] ?? 'Unknown'}')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToLocation(requestId, data),
                  icon: const Icon(Icons.directions),
                  label: const Text('Navigate'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _markAsCompleted(requestId),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _markAsInProgress(requestId),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }

  String _formatWasteCategories(dynamic categories) {
    if (categories == null) return 'Unknown';

    if (categories is List) {
      return categories.join(', ');
    }

    try {
      // Try to parse if it's a string like "[Plastic, Glass]"
      final String str = categories.toString();
      return str
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .join(', ');
    } catch (e) {
      return categories.toString();
    }
  }

  String _formatPickupDate(dynamic timestamp) {
    if (timestamp == null) return 'Not scheduled';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pickupDay = DateTime(date.year, date.month, date.day);

      if (pickupDay == today) {
        return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (pickupDay == today.add(const Duration(days: 1))) {
        return 'Tomorrow at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    }
    return timestamp.toString();
  }

  void _navigateToLocation(String requestId, Map<String, dynamic> data) async {
    Navigator.pop(context); // Close bottom sheet

    final userLatitude = data['userLatitude'];
    final userLongitude = data['userLongitude'];

    if (userLatitude == null || userLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location data not available for navigation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert to double if needed
    double lat, lng;
    try {
      lat = userLatitude is double
          ? userLatitude
          : double.parse(userLatitude.toString());
      lng = userLongitude is double
          ? userLongitude
          : double.parse(userLongitude.toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid location coordinates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String name = data['name'] ?? 'Pickup Location';

    // Show navigation options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Navigate to $name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Google Maps'),
              subtitle: const Text('Open in Google Maps app'),
              onTap: () => _openInGoogleMaps(lat, lng, name),
            ),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.green),
              title: const Text('Waze'),
              subtitle: const Text('Open in Waze app'),
              onTap: () => _openInWaze(lat, lng),
            ),
            ListTile(
              leading: const Icon(Icons.directions, color: Colors.orange),
              title: const Text('Apple Maps'),
              subtitle: const Text('Open in Apple Maps (iOS only)'),
              onTap: () => _openInAppleMaps(lat, lng, name),
            ),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.purple),
              title: const Text('Show Route on Map'),
              subtitle: const Text('Display route in this app'),
              onTap: () => _showRouteOnMap(lat, lng),
            ),
          ],
        ),
      ),
    );
  }

  void _openInGoogleMaps(double lat, double lng, String name) async {
    Navigator.pop(context);
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    _openUrl(url);
  }

  void _openInWaze(double lat, double lng) async {
    Navigator.pop(context);
    final url = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
    _openUrl(url);
  }

  void _openInAppleMaps(double lat, double lng, String name) async {
    Navigator.pop(context);
    final url = 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
    _openUrl(url);
  }

  void _showRouteOnMap(double lat, double lng) async {
    Navigator.pop(context);

    // Get real route using Google Directions API
    await _getDirectionsRoute(_initialPosition, LatLng(lat, lng));

    // Calculate distance
    final distance = Geolocator.distanceBetween(
      _initialPosition.latitude,
      _initialPosition.longitude,
      lat,
      lng,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Route shown. Distance: ${(distance / 1000).toStringAsFixed(2)} km',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
    }
  }

  Future<void> _markAsInProgress(String requestId) async {
    try {
      Navigator.pop(context); // Close bottom sheet

      await FirebaseFirestore.instance
          .collection('pickup_requests')
          .doc(requestId)
          .update({
            'status': 'in_progress',
            'startedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup marked as in progress!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating pickup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsCompleted(String requestId) async {
    try {
      Navigator.pop(context); // Close bottom sheet

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as Completed'),
          content: const Text(
            'Are you sure you want to mark this pickup as completed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await FirebaseFirestore.instance
            .collection('pickup_requests')
            .doc(requestId)
            .update({
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });

        // Remove marker from map
        setState(() {
          _markers.removeWhere((marker) => marker.markerId.value == requestId);
        });

        // If this was the nearest location, recalculate route to next nearest
        if (requestId == _nearestLocationId) {
          await _drawRouteToNearestLocation();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pickup marked as completed!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing pickup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fitMarkersInView() {
    if (_markers.length <= 1) return;

    final bounds = _calculateBounds(_markers);
    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  LatLngBounds _calculateBounds(Set<Marker> markers) {
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Routes'),
        actions: [
          if (_nearestLocationId != null)
            IconButton(
              icon: const Icon(Icons.near_me),
              tooltip: 'Navigate to nearest',
              onPressed: _navigateToNearestLocation,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _markers.clear();
                _polylines.clear();
                _isLoading = true;
                _errorMessage = null;
                _nearestLocationId = null;
                _nearestDistance = null;
              });
              _initializeMap();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map data...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _initializeMap();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_markers.length > 1) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _fitMarkersInView();
                      });
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                  mapToolbarEnabled: true,
                ),
                // Nearest location info card
                if (_nearestLocationId != null && _nearestDistance != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Next Pickup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${(_nearestDistance! / 1000).toStringAsFixed(2)} km away',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.directions),
                              onPressed: _navigateToNearestLocation,
                              tooltip: 'Navigate',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // API Key configuration notice
                if (_googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY')
                  Positioned(
                    bottom: 100,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.orange.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Configure Google Maps API key for road routing',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showApiKeyDialog(),
                              child: const Text('Setup'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_nearestLocationId != null)
            FloatingActionButton(
              heroTag: "navigate",
              mini: true,
              backgroundColor: Colors.orange,
              onPressed: _navigateToNearestLocation,
              child: const Icon(Icons.navigation, color: Colors.white),
            ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "center",
            mini: true,
            onPressed: () {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(_initialPosition, 16),
              );
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: () {
              setState(() {
                _markers.clear();
                _polylines.clear();
                _isLoading = true;
                _nearestLocationId = null;
                _nearestDistance = null;
              });
              _initializeMap();
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  // NEW METHOD: Show API key setup dialog
  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Maps API Setup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To enable road-following routes, you need to:'),
            SizedBox(height: 8),
            Text('1. Get a Google Maps API key'),
            Text('2. Enable Directions API'),
            Text('3. Replace YOUR_GOOGLE_MAPS_API_KEY in the code'),
            SizedBox(height: 8),
            Text(
              'Without API key, the app will show direct line routes.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openUrl(
                'https://developers.google.com/maps/documentation/directions/get-api-key',
              );
            },
            child: const Text('Get API Key'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Add to pubspec.yaml:
// dependencies:
//   http: ^1.1.0  # For API calls
