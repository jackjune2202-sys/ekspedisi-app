// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/receptionist/input_barang_screen.dart';
import '../../presentation/screens/receptionist/daftar_ekspedisi_screen.dart';
import '../../presentation/screens/security/security_home_screen.dart';
import '../../presentation/screens/security/ambil_barang_screen.dart';
import '../../presentation/screens/report/laporan_screen.dart';
import '../../presentation/screens/shared/detail_ekspedisi_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/input-barang',
        builder: (context, state) => const InputBarangScreen(),
      ),
      GoRoute(
        path: '/daftar-ekspedisi',
        builder: (context, state) => const DaftarEkspedisiScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityHomeScreen(),
      ),
      GoRoute(
        path: '/security/ambil/:id',
        builder: (context, state) => AmbilBarangScreen(
          ekspedisiId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) => DetailEkspedisiScreen(
          ekspedisiId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/laporan',
        builder: (context, state) => const LaporanScreen(),
      ),
    ],
  );
});