import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../ads/presentation/ad_banner_section.dart';
import '../../ads/data/ad_dtos.dart';
import '../../../shared/widgets/school_card.dart';
import '../../../shared/widgets/custom_navigation.dart';
import '../../auth/state/auth_controller.dart';
import '../../schools/state/compare_cart.dart';
import '../state/recommendations_controller.dart';
import '../../schools/data/school_repository.dart';

/// Parent home — `GET /api/recommendations` ranked schools with the score
/// breakdown surfaced under each card. The breakdown is what differentiates
/// this view from the plain `/schools` browse list.
class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.watch(recommendationsControllerProvider);
    final state = ctl.state;
    final user = ref.watch(authControllerProvider).user;
    final cart = ref.watch(compareCartProvider);

    return ResponsiveShell(
      title: 'Recommended for you',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ctl.refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: cart.length >= CompareCart.minItems
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/compare/new'),
              icon: const Icon(Icons.compare_arrows),
              label: Text('Compare ${cart.length}'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null)
            Row(
              children: [
                Text('Welcome, ${user.fullName}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/preferences'),
                  icon: const Icon(Icons.tune),
                  label: const Text('Add/change preferences'),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            'Schools ranked using your stored preferences. Tap a school to see details, or '
            'add 2–5 to the compare cart.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SmartNavigationSuggestions(
            currentPath: '/',
            suggestions: _getSuggestionsForParent(cart.length),
            onSuggestionTap: (path) => context.go(path),
          ),
          const SizedBox(height: 16),
          const AdBannerSection(
            placement: AdPlacementType.banner,
            limit: 1,
          ),
          const SizedBox(height: 16),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            _ErrorBlock(message: state.error!, onRetry: () => ctl.refresh())
          else if (state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No recommendations yet.\nTry browsing schools to seed '
                  'your preferences.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = state.items[i];
                final inCart = cart.contains(r.school.id);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SchoolCard(
                      school: r.school,
                      onTap: () async {
                        // Navigate to detail
                        context.go(
                            '/schools/${r.school.id}?recommendationId=${state.historyId}');

                        // Send feedback (fire-and-forget)
                        if (state.historyId != null) {
                          try {
                            print("historyId: ${state.historyId}");
                            ref
                                .read(schoolRepositoryProvider)
                                .sendRecommendationFeedback(
                                  historyId: state.historyId!,
                                  result: 'OPENED',
                                  schoolId: r.school.id,
                                );
                          } catch (e) {
                            // Log error silently to not block UI
                          }
                        }
                      },
                      trailing: IconButton(
                        tooltip:
                            inCart ? 'Remove from compare' : 'Add to compare',
                        icon: Icon(
                          inCart
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: inCart
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        onPressed: () {
                          if (inCart) {
                            cart.remove(r.school.id);
                          } else if (!cart.add(r.school)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Compare cart is full (max 5).')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

/// Get context-aware navigation suggestions for parents
List<NavigationSuggestion> _getSuggestionsForParent(int cartItemCount) {
  final suggestions = <NavigationSuggestion>[];

  // Always suggest browsing schools
  suggestions.add(const NavigationSuggestion(
    label: 'Browse Schools',
    icon: Icons.search,
    path: '/schools',
    reason: 'Explore all available schools',
  ));

  // Suggest announcements for parents
  suggestions.add(const NavigationSuggestion(
    label: 'Announcements',
    icon: Icons.campaign,
    path: '/announcements',
    reason: 'Latest updates from schools',
  ));

  // Suggest compare when they have items in cart
  if (cartItemCount >= 2) {
    suggestions.add(NavigationSuggestion(
      label: 'Compare $cartItemCount Schools',
      icon: Icons.compare_arrows,
      path: '/compare/new',
      reason: 'You have schools ready to compare',
    ));
  } else if (cartItemCount == 1) {
    suggestions.add(const NavigationSuggestion(
      label: 'Add More to Compare',
      icon: Icons.add_circle,
      path: '/schools',
      reason: 'Add at least one more school to compare',
    ));
  }

  // Suggest forum for community engagement
  suggestions.add(const NavigationSuggestion(
    label: 'Community Forum',
    icon: Icons.forum,
    path: '/forum',
    reason: 'Connect with other parents',
  ));

  return suggestions;
}
