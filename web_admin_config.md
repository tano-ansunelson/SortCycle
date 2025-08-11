# SortCycle Web Admin Configuration Guide

## 🚀 Quick Start

### 1. Run Web Admin Locally
```bash
# Navigate to your project directory
cd /d:/dev/flutter_application_1

# Run the web admin app
flutter run -d chrome --target lib/web_app/web_main.dart
```

### 2. Build for Production
```bash
# Build the web admin app
flutter build web --target lib/web_app/web_main.dart

# The built files will be in build/web/
```

## 🔧 Configuration Files

### Firebase Configuration
The web admin app uses the same Firebase configuration as your mobile app:
- `lib/firebase_options.dart` - Firebase configuration
- Same project ID and settings

### Admin User Setup
Before you can log in, you need to create an admin user:

1. **Use Firebase Console** (Recommended):
   - Go to Firebase Console > Authentication
   - Add a new user with admin email/password
   - Go to Firestore > Create collection `admins`
   - Add document with user's UID and admin data

2. **Use Cloud Functions** (Advanced):
   ```bash
   # Call the createAdminUser function
   curl -X POST https://your-region-your-project.cloudfunctions.net/createAdminUser \
     -H "Content-Type: application/json" \
     -d '{
       "email": "admin@sortcycle.com",
       "password": "securepassword",
       "name": "Admin User",
       "role": "admin"
     }'
   ```

## 📁 File Structure

```
lib/web_app/
├── web_main.dart                    # ✅ Main entry point
├── web_providers/
│   └── admin_provider.dart          # ✅ Admin state management
├── web_screens/
│   ├── admin_login_screen.dart      # ✅ Admin login interface
│   ├── admin_dashboard.dart         # ✅ Main admin dashboard
│   ├── admin_users_management_screen.dart      # ✅ User management
│   ├── admin_collector_management_screen.dart  # ✅ Collector management
│   ├── admin_pickup_management_screen.dart     # ✅ Pickup request management
│   └── admin_marketplace_management_screen.dart # ✅ Marketplace management
├── web_routes.dart                  # ✅ Web admin routing
└── README.md                        # ✅ Complete documentation
```

## 🌐 Web-Specific Files

- `web/index_admin.html` - Custom HTML for admin web app
- `web_admin_config.md` - This configuration guide

## 🔐 Admin Features

### ✅ Implemented
- **Authentication**: Secure login with Firebase
- **Dashboard**: Real-time statistics overview
- **User Management**: View, search, activate/deactivate users
- **Collector Management**: View, search, manage collector status
- **Pickup Management**: Monitor pickup requests
- **Marketplace Management**: View and delete marketplace items

### 🚧 Future Enhancements
- Advanced analytics
- Bulk operations
- Export functionality
- Real-time notifications
- Audit logging

## 🚨 Troubleshooting

### Common Issues

1. **"Admin access not found" error**:
   - Ensure admin user exists in `admins` collection
   - Check Firebase Authentication user exists

2. **Build errors**:
   - Ensure all dependencies are installed: `flutter pub get`
   - Check Firebase configuration is correct

3. **Web app not loading**:
   - Clear browser cache
   - Check browser console for errors
   - Ensure Firebase is properly initialized

### Debug Mode
```bash
# Run with debug information
flutter run -d chrome --target lib/web_app/web_main.dart --debug
```

## 📱 Mobile vs Web

- **Mobile App**: `lib/mobile_app/` - For users and collectors
- **Web Admin**: `lib/web_app/` - For administrators only
- **Shared**: Firebase backend, models, and utilities

## 🔒 Security Notes

- Admin users are verified against `admins` collection
- All admin operations require authentication
- Firebase App Check integration for additional security
- Role-based access control implemented

## 📞 Support

For technical issues:
1. Check Firebase Console for authentication errors
2. Verify admin user exists in Firestore
3. Check browser console for JavaScript errors
4. Ensure all dependencies are up to date

---

**Ready to use!** 🎉
Run `flutter run -d chrome --target lib/web_app/web_main.dart` to start the admin panel.
