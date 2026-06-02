import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
  }
}

// Provider for the onboarding service
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

// Provider to track if user has seen onboarding
final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  return await service.hasSeenOnboarding();
});