import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/centers/presentation/centers_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/opportunities/presentation/opportunities_screen.dart';
import '../../features/opportunities/presentation/opportunity_detail_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/profile/presentation/profile_view_screen.dart';
import '../../features/progress/presentation/journey_screen.dart';
import '../../features/recommendations/domain/opportunity_query.dart';
import '../../features/recommendations/presentation/recommendations_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const places = '/places';
  static const opportunities = '/opportunities';
  static const account = '/account';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const onboardingProfile = '/profile/edit?onboarding=1';
  static const recommendations = '/recommendations';
  static const settings = '/settings';
  static String opportunity(String id) => '/opportunity/$id';
  static String assistantFrom(String tab) => '$tab/assistant';

  /// Tab roots are switched with `go`, everything else is pushed.
  static const tabs = {home, places, opportunities, account};

  static const _public = {splash, welcome, login, register};
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final signedIn = ref.read(authProvider) != null;
      if (!signedIn && !Routes._public.contains(state.matchedLocation)) {
        return Routes.welcome;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.profile,
        builder: (_, _) => const ProfileViewScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                ProfileSetupScreen(onboarding: state.uri.queryParameters['onboarding'] == '1'),
          ),
        ],
      ),
      GoRoute(
        path: Routes.recommendations,
        builder: (_, state) =>
            RecommendationsScreen(query: OpportunityQuery.fromParams(state.uri.queryParameters)),
      ),
      GoRoute(
        path: '/opportunity/:id',
        builder: (_, state) => OpportunityDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) => const HomeScreen(),
                routes: [GoRoute(path: 'assistant', builder: (_, _) => const AssistantScreen())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.places,
                builder: (_, _) => const CentersScreen(),
                routes: [GoRoute(path: 'assistant', builder: (_, _) => const AssistantScreen())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.opportunities,
                builder: (_, state) => OpportunitiesScreen(
                  initialQuery: state.uri.queryParameters['q'],
                  initialType: state.uri.queryParameters['type'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.account, builder: (_, _) => const JourneyScreen())],
          ),
        ],
      ),
    ],
  );
});

extension TifawtNavigation on BuildContext {
  /// Opens an in-app route coming from data (assistant actions, FAQ).
  void openRoute(String route) {
    final path = Uri.parse(route).path;
    Routes.tabs.contains(path) ? go(route) : push(route);
  }
}
