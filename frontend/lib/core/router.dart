import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ads/presentation/ad_payment_screen.dart';
import '../features/ads/presentation/ad_request_screen.dart';
import '../features/ads/presentation/moderation_ad_queue_screen.dart';
import '../shared/utils/animations.dart';
import '../features/landing/presentation/landing_screen.dart';
import '../features/schools/presentation/manage_followed_schools_screen.dart';
import '../features/moderation/presentation/admin_user_create_screen.dart';
import '../features/admin/presentation/admin_announcements_screen.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/admin/presentation/admin_school_manage_screen.dart';
import '../features/admin/presentation/admin_school_create_screen.dart';
import '../features/announcements/presentation/announcement_detail_screen.dart';
import '../features/announcements/presentation/announcements_feed_screen.dart';
import '../features/auth/presentation/email_verify_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/comparisons/presentation/comparison_detail_screen.dart';
import '../features/comparisons/presentation/comparisons_list_screen.dart';
import '../features/comparisons/presentation/new_comparison_screen.dart';
import '../features/forum/presentation/forum_detail_screen.dart';
import '../features/forum/presentation/forum_list_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/moderation/presentation/moderation_reports_screen.dart';
import '../features/moe/presentation/moe_announcements_screen.dart';
import '../features/moe/presentation/moe_dashboard_screen.dart';
import '../features/moe/presentation/moe_home_screen.dart';
import '../features/moe/presentation/moe_verification_queue_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/preferences/presentation/preferences_screen.dart';
import '../features/schools/presentation/school_detail_screen.dart';
import '../features/schools/presentation/schools_list_screen.dart';
import '../features/auth/presentation/phone_verify_screen.dart';
import '../features/demographics/presentation/demographics_manage_screen.dart';
import '../features/analytics/presentation/school_analytics_screen.dart';

import '../features/achievements/presentation/achievements_manage_screen.dart';
import '../features/achievements/presentation/achievement_detail_screen.dart';
import '../features/achievements/presentation/staff_breakdown_screen.dart';
import '../features/achievements/presentation/moe_achievement_review_screen.dart';
import '../features/reviews/presentation/school_reviews_screen.dart';
import '../features/ads/presentation/ad_payment_success_screen.dart';

/// Lists routes that anyone (logged in or not) is allowed to hit. Email-verify
/// + reset-password are public because they're entered from email deep links;
/// hiding them behind auth would be a chicken-and-egg loop.
const _publicRoutes = <String>{
  '/landing',
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/verify-email',
  '/verify-phone',
  '/advertise',
};

bool _isPublicAdvertiseRoute(String location) {
  return location.startsWith('/advertise');
}

final routerProvider = Provider<GoRouter>((ref) {
  // We deliberately `read` rather than `watch` here. The router itself only
  // needs the AuthController instance once (to wire `refreshListenable`); the
  // `redirect` callback below closes over `auth` and re-runs on every nav
  // event, so it always sees the latest auth state.
  final auth = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: '/landing',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.initializing) return null;

      final goingPublic = _publicRoutes.any(
            (p) => state.matchedLocation.startsWith(p),
          ) ||
          _isPublicAdvertiseRoute(state.matchedLocation);

      if (!auth.isAuthenticated && !goingPublic) {
        return '/landing';
      }
      if (auth.isAuthenticated && goingPublic) {
        if (state.matchedLocation.startsWith('/verify-email') ||
            state.matchedLocation.startsWith('/reset-password') ||
            state.matchedLocation.startsWith('/advertise/pay') ||
            state.matchedLocation.startsWith('/advertise/success')) {
          return null;
        }
        if (state.matchedLocation == '/landing') {
          return '/';
        }
        return '/';
      }
      return null;
    },
    routes: [
      // Public routes with smooth fade transitions
      GoRoute(
        path: '/landing',
        pageBuilder: (context, state) => AppAnimations.fadeInScale(
          key: state.pageKey,
          child: const LandingScreen(),
        ),
      ),

      GoRoute(
        path: '/advertise/success/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid advertisement id')),
            );
          }
          return AdPaymentSuccessScreen(adId: id);
        },
      ),
      GoRoute(
        path: '/advertise',
        builder: (_, __) => const AdRequestScreen(),
      ),
      GoRoute(
        path: '/advertise/pay/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid advertisement id')),
            );
          }
          return AdPaymentScreen(adId: id);
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppAnimations.fadeInScale(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => AppAnimations.fadeInScale(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => AppAnimations.fadeInScale(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => AppAnimations.smoothFade(
          key: state.pageKey,
          child: ResetPasswordScreen(
            token: state.uri.queryParameters['token'],
          ),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => AppAnimations.smoothFade(
          key: state.pageKey,
          child: EmailVerifyScreen(
            token: state.uri.queryParameters['token'],
          ),
        ),
      ),
      GoRoute(
        path: '/verify-phone',
        pageBuilder: (context, state) => AppAnimations.smoothFade(
          key: state.pageKey,
          child: PhoneVerifyScreen(
            phone: state.uri.queryParameters['phone'] ?? '',
          ),
        ),
      ),

      // Main app routes with unique transitions
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/followed-schools',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const ManageFollowedSchoolsScreen(),
        ),
      ),
      GoRoute(
        path: '/preferences',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const PreferencesScreen(),
        ),
      ),
      GoRoute(
        path: '/schools',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const SchoolsListScreen(),
        ),
      ),
      GoRoute(
        path: '/schools/:id',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');

          // Extract the query parameter from the URI context
          final recommendationIdRaw =
              state.uri.queryParameters['recommendationId'];
          final recommendationId = recommendationIdRaw != null
              ? int.tryParse(recommendationIdRaw)
              : null;

          if (id == null) {
            return AppAnimations.noTransition(
              key: state.pageKey,
              child: Scaffold(
                body: Center(child: Text('Invalid school id: $raw')),
              ),
            );
          }

          return AppAnimations.expandFromCenter(
            key: state.pageKey,
            child: SchoolDetailScreen(
              schoolId: id,
              recommendationId: recommendationId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/schools/:id/reviews',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return AppAnimations.noTransition(
              key: state.pageKey,
              child: Scaffold(
                body: Center(child: Text('Invalid school id: $raw')),
              ),
            );
          }
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: SchoolReviewsScreen(schoolId: id),
          );
        },
      ),
      GoRoute(
        path: '/compare',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const ComparisonsListScreen(),
        ),
      ),
      GoRoute(
        path: '/compare/new',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const NewComparisonScreen(),
        ),
      ),
      GoRoute(
        path: '/compare/:id',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return AppAnimations.noTransition(
              key: state.pageKey,
              child: Scaffold(
                body: Center(child: Text('Invalid comparison id: $raw')),
              ),
            );
          }
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: ComparisonDetailScreen(comparisonId: id),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/announcements',
        pageBuilder: (context, state) {
          final schoolIdRaw = state.uri.queryParameters['schoolId'];
          final schoolId = schoolIdRaw != null ? int.tryParse(schoolIdRaw) : null;
          return AppAnimations.bounceSlide(
            key: state.pageKey,
            child: AnnouncementsFeedScreen(schoolId: schoolId),
          );
        },
      ),
      GoRoute(
        path: '/announcements/:id',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return AppAnimations.noTransition(
              key: state.pageKey,
              child: Scaffold(
                body: Center(child: Text('Invalid announcement id: $raw')),
              ),
            );
          }
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: AnnouncementDetailScreen(announcementId: id),
          );
        },
      ),
      GoRoute(
        path: '/forum',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const ForumListScreen(),
        ),
      ),
      GoRoute(
        path: '/forum/:id',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return AppAnimations.noTransition(
              key: state.pageKey,
              child: Scaffold(
                body: Center(child: Text('Invalid post id: $raw')),
              ),
            );
          }
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: ForumDetailScreen(postId: id),
          );
        },
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const AdminHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/announcements',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const AdminAnnouncementsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/schools/create',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const AdminSchoolCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/schools/:id',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return AppAnimations.noTransition(
              key: state.pageKey,
              child: Scaffold(
                body: Center(child: Text('Invalid school id: $raw')),
              ),
            );
          }
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: AdminSchoolManageScreen(schoolId: id),
          );
        },
      ),

      GoRoute(
        path: '/moe',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const MoeHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/moe/dashboard',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const MoeDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/moe/verifications',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const MoeVerificationQueueScreen(),
        ),
      ),
      GoRoute(
        path: '/moe/announcements',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const MoeAnnouncementsScreen(),
        ),
      ),
      GoRoute(
        path: '/moderation',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const ModerationReportsScreen(),
        ),
      ),
      GoRoute(
        path: '/moderation/create-user',
        pageBuilder: (context, state) => AppAnimations.slideInFromRight(
          key: state.pageKey,
          child: const AdminUserCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/schools/:schoolId/demographics',
        pageBuilder: (context, state) {
          final schoolId = int.parse(state.pathParameters['schoolId']!);
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: DemographicsManageScreen(schoolId: schoolId),
          );
        },
      ),
      GoRoute(
        path: '/schools/:schoolId/analytics',
        pageBuilder: (_, state) {
          final schoolId = int.parse(state.pathParameters['schoolId']!);
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: SchoolAnalyticsScreen(schoolId: schoolId),
          );
        },
      ),
      GoRoute(
        path: '/admin/schools/:schoolId/achievements',
        pageBuilder: (context, state) {
          final schoolId = int.parse(state.pathParameters['schoolId']!);
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: AchievementsManageScreen(schoolId: schoolId),
          );
        },
      ),
      GoRoute(
        path: '/admin/schools/:schoolId/achievements/:achievementId',
        pageBuilder: (context, state) {
          final schoolId = int.parse(state.pathParameters['schoolId']!);
          final achievementId =
              int.parse(state.pathParameters['achievementId']!);
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: AchievementDetailScreen(
                schoolId: schoolId, achievementId: achievementId),
          );
        },
      ),
      GoRoute(
        path: '/admin/schools/:schoolId/staff-breakdown',
        pageBuilder: (context, state) {
          final schoolId = int.parse(state.pathParameters['schoolId']!);
          return AppAnimations.slideInFromRight(
            key: state.pageKey,
            child: StaffBreakdownScreen(schoolId: schoolId),
          );
        },
      ),
      GoRoute(
        path: '/moe/achievements',
        pageBuilder: (_, __) => AppAnimations.slideInFromRight(
          key: const ValueKey('moe-achievements'),
          child: const MoeAchievementReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/moderation/ads',
        builder: (_, __) => const ModerationAdQueueScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
