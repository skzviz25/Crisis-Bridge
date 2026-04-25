import 'package:crisis_bridge/providers/auth_provider.dart';
import 'package:crisis_bridge/providers/map_provider.dart';
import 'package:crisis_bridge/providers/sos_provider.dart';
import 'package:crisis_bridge/core/theme.dart';
import 'package:crisis_bridge/screens/role_select_screen.dart';
import 'package:crisis_bridge/screens/login_screen.dart';
import 'package:crisis_bridge/screens/register_screen.dart';
import 'package:crisis_bridge/screens/staff/staff_home_screen.dart';
import 'package:crisis_bridge/screens/staff/map_builder_screen.dart';
import 'package:crisis_bridge/screens/staff/map_update_screen.dart';
import 'package:crisis_bridge/screens/staff/incident_dashboard_screen.dart';
import 'package:crisis_bridge/screens/user/user_home_screen.dart';
import 'package:crisis_bridge/screens/user/qr_scanner_screen.dart';
import 'package:crisis_bridge/screens/user/route_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CrisisBridgeApp extends StatelessWidget {
  const CrisisBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
      ],
      child: MaterialApp.router(
        title: 'Crisis Bridge',
        theme: AppTheme.dark(),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const RoleSelectScreen()),
    GoRoute(path: '/login', builder: (_, s) => LoginScreen(role: s.uri.queryParameters['role'] ?? 'staff')),
    GoRoute(path: '/register', builder: (_, s) => RegisterScreen(role: s.uri.queryParameters['role'] ?? 'staff')),
    GoRoute(path: '/staff/home', builder: (_, __) => const StaffHomeScreen()),
    GoRoute(path: '/staff/map-builder', builder: (_, __) => const MapBuilderScreen()),
    GoRoute(
      path: '/staff/map-update/:mapId',
      builder: (_, s) => MapUpdateScreen(mapId: s.pathParameters['mapId']!),
    ),
    GoRoute(path: '/staff/incidents', builder: (_, __) => const IncidentDashboardScreen()),
    GoRoute(path: '/user/home', builder: (_, __) => const UserHomeScreen()),
    GoRoute(path: '/user/scan', builder: (_, __) => const QrScannerScreen()),
    GoRoute(
      path: '/user/route/:mapId',
      builder: (_, s) => RouteScreen(mapId: s.pathParameters['mapId']!),
    ),
  ],
);