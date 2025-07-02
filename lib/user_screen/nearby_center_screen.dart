import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NearbyCentersScreen extends StatefulWidget {
  const NearbyCentersScreen({super.key});

  @override
  State<NearbyCentersScreen> createState() => _NearbyCentersScreenState();
}

class _NearbyCentersScreenState extends State<NearbyCentersScreen> {
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(
    37.7749,
    -122.4194,
  ); // Default to San Francisco
  final Set<Marker> _markers = {};

  // Mock data for recycling centers (could be from backend/API later)
  final List<Map<String, dynamic>> _centers = [
    {
      'name': 'Eco Drop-Off Point',
      'type': ['Plastic', 'Glass'],
      'lat': 37.7749,
      'lng': -122.4194,
    },
    {
      'name': 'Battery Recycle Hub',
      'type': ['E-waste', 'Batteries'],
      'lat': 37.7790,
      'lng': -122.4294,
    },
    {
      'name': 'PaperBin Recycling',
      'type': ['Paper', 'Cardboard'],
      'lat': 37.7840,
      'lng': -122.4094,
    },
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      setState(() {
        _initialPosition = LatLng(pos.latitude, pos.longitude);
      });
      _loadMarkers();
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _loadMarkers() {
    for (var center in _centers) {
      _markers.add(
        Marker(
          markerId: MarkerId(center['name']),
          position: LatLng(center['lat'], center['lng']),
          infoWindow: InfoWindow(
            title: center['name'],
            snippet: "Accepts: ${center['type'].join(', ')}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Recycling Centers"),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14,
        ),
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
