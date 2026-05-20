import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/report_model.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/history/report_detail_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/report/report_create_screen.dart';

// Admin screens
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_report_list_screen.dart';
import '../../screens/admin/admin_report_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/otp';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && state.matchedLocation == '/login') {
      return '/home'; // Will be handled better in login_screen upon login, but default to home if hitting /login directly while logged in.
    }

    if (isLoggedIn && state.matchedLocation.startsWith('/admin')) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          final role = profileData?['role'] as String? ?? 'warga';
          if (role != 'admin' && role != 'petugas') {
            return '/home';
          }
        } catch (_) {
          return '/home';
        }
      } else {
        return '/login';
      }
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map) {
          final email = extra['email'] as String? ?? '';
          final fullName = extra['fullName'] as String?;
          return OtpScreen(email: email, fullName: fullName);
        }
        final email = extra as String? ?? '';
        return OtpScreen(email: email);
      },
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/report/create',
      builder: (context, state) => const ReportCreateScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/history/:id',
      builder: (context, state) {
        final report = state.extra as ReportModel;
        return ReportDetailScreen(report: report);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // Admin routes
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminReportListScreen(),
    ),
    GoRoute(
      path: '/admin/reports/:id',
      builder: (context, state) {
        final report = state.extra as ReportModel;
        return AdminReportDetailScreen(report: report);
      },
    ),
  ],
);
