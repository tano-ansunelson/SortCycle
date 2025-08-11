# SortCycle Web Admin Application

This is the web-based admin panel for the SortCycle waste collection platform.

## Structure

```
lib/web_app/
├── web_main.dart                    # Main entry point for web admin
├── web_providers/
│   └── admin_provider.dart          # Admin state management
├── web_screens/
│   ├── admin_login_screen.dart      # Admin login interface
│   ├── admin_dashboard.dart         # Main admin dashboard
│   ├── admin_users_management_screen.dart      # User management
│   ├── admin_collector_management_screen.dart  # Collector management
│   ├── admin_pickup_management_screen.dart     # Pickup request management
│   └── admin_marketplace_management_screen.dart # Marketplace management
└── web_routes.dart                  # Web admin routing
```

## Features

### 🔐 Authentication
- Secure admin login with Firebase Auth
- Admin role verification
- Automatic session management

### 📊 Dashboard
- Real-time statistics overview
- Quick access to all management functions
- System health monitoring

### 👥 User Management
- View all registered users
- Manage user accounts (activate/deactivate)
- User activity monitoring

### 🚛 Collector Management
- View all waste collectors
- Manage collector status
- Monitor collector performance

### 🗑️ Pickup Management
- View all pickup requests
- Monitor request status
- Manage request assignments

### 🛍️ Marketplace Management
- View marketplace items
- Moderate listings
- Manage item approvals

## How to Run

### 1. Build for Web
```bash
flutter build web --target lib/web_app/web_main.dart
```

### 2. Serve Locally
```bash
flutter run -d chrome --target lib/web_app/web_main.dart
```

### 3. Deploy to Firebase Hosting
```bash
# Update firebase.json to include web admin
firebase deploy --only hosting:admin
```

## Firebase Configuration

The web admin app uses the same Firebase project as your mobile app:

- **Authentication**: Firebase Auth for admin login
- **Firestore**: Admin data, user management, analytics
- **Storage**: File management (if needed)

## Admin Access Setup

### 1. Create Admin User
Use the Firebase Cloud Function to create admin users:

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

### 2. Admin Permissions
Admins have access to:
- Read/Write access to all collections
- User management capabilities
- System monitoring and analytics

## Security Features

- **Role-based access control**
- **Firebase App Check** integration
- **Secure authentication** flow
- **Data validation** and sanitization

## Development Notes

- Built with Flutter Web
- Responsive design for desktop and tablet
- Material Design 3 components
- Real-time data updates with Firestore streams

## Future Enhancements

- [ ] Advanced analytics dashboard
- [ ] Bulk operations for user management
- [ ] Export functionality for reports
- [ ] Real-time notifications
- [ ] Audit logging system
- [ ] Multi-language support

## Support

For technical support or feature requests, contact the development team.
