import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_application_1/mobile_app/services/profile_picture_service.dart';

class ProfilePictureWidget extends StatelessWidget {
  final String? profilePictureUrl;
  final String userType; // 'user' or 'collector'
  final double size;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final bool isOnline;
  final Color? borderColor;
  final double borderWidth;

  const ProfilePictureWidget({
    super.key,
    this.profilePictureUrl,
    required this.userType,
    this.size = 60,
    this.showEditButton = false,
    this.onEditPressed,
    this.isOnline = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile Picture
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor ?? Colors.grey.shade300,
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(child: _buildProfileImage()),
        ),

        // Online Status Indicator
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),

        // Edit Button
        if (showEditButton && onEditPressed != null)
          Positioned(
            bottom: -2,
            right: -2,
            child: GestureDetector(
              onTap: onEditPressed,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.edit, color: Colors.white, size: size * 0.15),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      return Image.network(
        profilePictureUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: Center(
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfileImage();
        },
      );
    } else {
      return _buildDefaultProfileImage();
    }
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: Icon(
        userType == 'collector' ? Icons.person_outline : Icons.person,
        size: size * 0.5,
        color: Colors.grey.shade400,
      ),
    );
  }
}

// Compact version for lists and cards
class CompactProfilePictureWidget extends StatelessWidget {
  final String? profilePictureUrl;
  final String userType;
  final double size;
  final bool isOnline;

  const CompactProfilePictureWidget({
    super.key,
    this.profilePictureUrl,
    required this.userType,
    this.size = 40,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ClipOval(child: _buildProfileImage()),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      return Image.network(
        profilePictureUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfileImage();
        },
      );
    } else {
      return _buildDefaultProfileImage();
    }
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: Icon(
        userType == 'collector' ? Icons.person_outline : Icons.person,
        size: size * 0.5,
        color: Colors.grey.shade400,
      ),
    );
  }
}
