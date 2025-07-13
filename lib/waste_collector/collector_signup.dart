import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes/app_route.dart';
// import 'package:geolocator/geolocator.dart';

class CollectorSignup extends StatefulWidget {
  final String role;
  const CollectorSignup({super.key, required this.role});

  @override
  State<CollectorSignup> createState() => _CollectorSignup();
}

class _CollectorSignup extends State<CollectorSignup> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final townController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  //Position? _currentPosition;
  //String _locationStatus = 'Location not set';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    townController.dispose();
    super.dispose();
  }

  // Future<void> _getCurrentLocation() async {
  //   setState(() {
  //     _locationStatus = "Getting location...";
  //   });

  //   try {
  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       if (permission == LocationPermission.denied) {
  //         throw Exception('Location permission denied');
  //       }
  //     }

  //     if (permission == LocationPermission.deniedForever) {
  //       throw Exception('Location permission permanently denied');
  //     }

  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     setState(() {
  //       _currentPosition = position;
  //       _locationStatus =
  //           "Location set: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _locationStatus = "Failed to get location";
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF004D40),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Join EcoClassify",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 40),

                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration("Full Name", Icons.person),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Email
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration("Email", Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Town
                  TextFormField(
                    controller: townController,
                    decoration: _inputDecoration(
                      "Town/City",
                      Icons.location_city,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter town'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  TextFormField(
                    controller: phoneController,
                    decoration: _inputDecoration("Phone Number", Icons.phone),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Location Button
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton.icon(
                  //     icon: const Icon(Icons.location_on),
                  //     label: Text(_locationStatus),
                  //     onPressed: _getCurrentLocation,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.teal,
                  //       padding: const EdgeInsets.symmetric(vertical: 14),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(20),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 30),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Sign up",
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.signIn);
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      // if (_currentPosition == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text("Please set your location"),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      setState(() => _isLoading = true);

      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        final uid = userCredential.user!.uid;

        await FirebaseFirestore.instance.collection('collectors').doc(uid).set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'role': widget.role,
          'phone': phoneController.text.trim(),
          'town': townController.text.trim(),
          // 'latitude': _currentPosition!.latitude,
          //'longitude': _currentPosition!.longitude,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isLoading = false);

        Navigator.pushNamed(
          context,
          AppRoutes.collectorHome,
          arguments: {'role': 'collector'},
        );
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        String errorMsg = 'An error occurred';
        if (e.code == 'email-already-in-use') {
          errorMsg = 'This email is already in use.';
        } else if (e.code == 'weak-password') {
          errorMsg = 'Password should be at least 6 characters.';
        } else {
          errorMsg = e.message ?? errorMsg;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }
}
