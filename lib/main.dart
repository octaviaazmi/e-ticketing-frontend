import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ticket_list_screen.dart';
import 'screens/ticket_detail_screen.dart';
import 'screens/create_ticket_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/ticket_tracking_screen.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart'; // <--- IMPORT
import 'screens/user_management_screen.dart';
import 'screens/add_edit_user_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // <--- TAMBAHKAN
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'E-Ticketing Helpdesk',
            theme: themeProvider.themeData,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => SplashScreen(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/forgot-password': (context) => ForgotPasswordScreen(),
              '/dashboard': (context) => DashboardScreen(),
              '/tickets': (context) => TicketListScreen(),
              '/ticket-detail': (context) => TicketDetailScreen(),
              '/create-ticket': (context) => CreateTicketScreen(),
              '/profile': (context) => ProfileScreen(),
              '/settings': (context) => SettingsScreen(),
              '/notifications': (context) => NotificationScreen(),
              '/tracking': (context) => TicketTrackingScreen(),
              '/user-management': (context) => UserManagementScreen(),
              '/add-edit-user': (context) => AddEditUserScreen(),
            },
          );
        },
      ),
    );
  }
}