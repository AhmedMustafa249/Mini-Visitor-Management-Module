import 'package:flutter/material.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/visitors/ui/visitor_list_screen.dart';
import '../../features/visitors/ui/add_visitor_screen.dart';
import '../../features/visitors/ui/visitor_details_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String visitorList = '/visitors';
  static const String addVisitor = '/visitors/add';
  static const String visitorDetail = '/visitors/detail';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case AppRoutes.visitorList:
      return MaterialPageRoute(builder: (_) => const VisitorListScreen());
    case AppRoutes.addVisitor:
      return MaterialPageRoute(builder: (_) => const AddVisitorScreen());
    case AppRoutes.visitorDetail:
      final visitorId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => VisitorDetailsScreen(visitorId: visitorId),
      );
    default:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Route not found')),
        ),
      );
  }
}
