import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/venue/venue_detail_screen.dart';
import '../screens/venue/add_venue_screen.dart';
import '../screens/venue/edit_venue_screen.dart';
import '../screens/review/add_review_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/booking/owner_bookings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/owner/owner_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value.session != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuth = state.matchedLocation.startsWith('/auth');

      if (isSplash) return null;
      if (!isLoggedIn && !isAuth) return '/auth/login';
      if (isLoggedIn && isAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/venue/add', builder: (_, __) => const AddVenueScreen()),
      GoRoute(
        path: '/venue/:id/edit',
        builder: (_, state) => EditVenueScreen(venueId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/venue/:id',
        builder: (_, state) => VenueDetailScreen(venueId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/venue/:id/review',
        builder: (_, state) => AddReviewScreen(venueId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/venue/:id/booking',
        builder: (_, state) => BookingScreen(venueId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/owner/bookings', builder: (_, __) => const OwnerBookingsScreen()),
      GoRoute(path: '/owner/dashboard', builder: (_, __) => const OwnerDashboardScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});
