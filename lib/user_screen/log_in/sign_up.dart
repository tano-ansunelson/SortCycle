import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes/app_route.dart';
import 'package:flutter_application_1/service/email_verification.dart';

class SignUpScreen extends StatefulWidget {
  final String role;
  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildSignUpForm(),
                  const SizedBox(height: 30),
                  _buildSignInLink(),
                  //_buildSocialLogin(),
                  const SizedBox(height: 30),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, size: 50, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Join SortCyle',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your ${widget.role} account',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start your sustainable journey today',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              _buildNameField(),
              const SizedBox(height: 15),
              _buildEmailField(),
              const SizedBox(height: 15),
              _buildPhoneNumber(),
              const SizedBox(height: 15),
              _buildPasswordField(),
              const SizedBox(height: 15),
              _buildSignUpButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF4CAF50)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your full name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4CAF50)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneNumber() {
    return TextFormField(
      controller: phoneNumberController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixIcon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your phone number';
        }

        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4CAF50)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Create Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // Widget _buildSocialLogin() {
  //   return FadeTransition(
  //     opacity: _fadeAnimation,
  //     child: const Column(
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(child: Divider(color: Colors.white54)),
  //             Padding(
  //               padding: EdgeInsets.symmetric(horizontal: 16),
  //               child: Text(
  //                 'Or continue with',
  //                 style: TextStyle(color: Colors.white70),
  //               ),
  //             ),
  //             Expanded(child: Divider(color: Colors.white54)),
  //           ],
  //         ),
  //         SizedBox(height: 25),
  //         // Row(
  //         //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         //   children: [
  //         //     _buildSocialButton(Icons.g_mobiledata, 'Google'),
  //         //     _buildSocialButton(Icons.facebook, 'Facebook'),
  //         //     _buildSocialButton(Icons.apple, 'Apple'),
  //         //   ],
  //         // ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildSocialButton(IconData icon, String label) {
  //   return Container(
  //     width: 60,
  //     height: 60,
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(15),
  //       boxShadow: const [
  //         BoxShadow(
  //           color: Colors.black12,
  //           blurRadius: 10,
  //           offset: Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: IconButton(
  //       onPressed: () {
  //         // Handle social login - keeping original empty implementation
  //       },
  //       icon: Icon(icon, size: 30, color: Colors.grey[700]),
  //     ),
  //   );
  // }

  Widget _buildSignInLink() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Already have an account? ",
            style: TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.signIn);
            },
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Step 1: Create user with Firebase Auth
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        final uid = userCredential.user!.uid;

        // Step 2: Save role + name to Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneNumberController.text,
          'role': widget.role, // 👈 this is where role is saved
          'createdAt': FieldValue.serverTimestamp(),
          //'sortScore': 0,
        });

        setState(() {
          _isLoading = false;
        });

        // Step 3: Navigate to home screen based on role
        if (widget.role == 'collector') {
          Navigator.pushNamed(
            context,
            AppRoutes.collectorHome,
            arguments: {'role': 'collector'},
          );
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.home,
            arguments: {'role': 'User'},
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

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
