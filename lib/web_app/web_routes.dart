import 'package:flutter/material.dart';
import 'web_screens/admin_dashboard.dart';
import 'web_screens/admin_users_management_screen.dart';
import 'web_screens/admin_pickup_management_screen.dart';
import 'web_screens/admin_collector_management_screen.dart';
import 'web_screens/admin_marketplace_management_screen.dart';

class WebAdminRoutes {
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String collectors = '/collectors';
  static const String pickups = '/pickups';
  static const String marketplace = '/marketplace';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case users:
        return MaterialPageRoute(builder: (_) => const AdminUsersManagementScreen());
      case collectors:
        return MaterialPageRoute(builder: (_) => const AdminCollectorManagementScreen());
      case pickups:
        return MaterialPageRoute(builder: (_) => const AdminPickupManagementScreen());
      case marketplace:
        return MaterialPageRoute(builder: (_) => const AdminMarketplaceManagementScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('404')),
            body: const Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
