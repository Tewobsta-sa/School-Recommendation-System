import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/like_action.dart';
import '../../../shared/widgets/share_action.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/custom_components.dart';
import '../data/announcement_dtos.dart';
import '../state/announcements_feed_controller.dart';
import '../../auth/state/auth_controller.dart';
import '../../auth/data/auth_dtos.dart';
import '../../likes/data/like_dtos.dart';
import '../../reports/data/report_dtos.dart';

/// `/announcements` — public list of school + ministry announcements.
/// Parents get an additional "Followed schools only" toggle that bumps
/// the backend's `followedOnly=true` filter on; non-parents always see
/// every visible announcement.
/// 
/// If [schoolId] is provided, shows only announcements from that specific school.
class AnnouncementsFeedScreen extends ConsumerStatefulWidget {
  final int? schoolId;
  const AnnouncementsFeedScreen({super.key, this.schoolId});

  @override
  ConsumerState<AnnouncementsFeedScreen> createState() =>
      _AnnouncementsFeedScreenState();
}

class _AnnouncementsFeedScreenState
    extends ConsumerState<AnnouncementsFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(announcementsFeedControllerProvider);
      if (widget.schoolId != null) {
        controller.applyFilters(schoolId: widget.schoolId);
      }
      controller.ensureLoaded();
    });
  }

  bool _onScroll(ScrollNotification n) {
    final m = n.metrics;
    if (m.maxScrollExtent > 0 && m.pixels >= m.maxScrollExtent - 200) {
      ref.read(announcementsFeedControllerProvider).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ctl = ref.watch(announcementsFeedControllerProvider);
    final theme = Theme.of(context);

    return ResponsiveShell(
      title: widget.schoolId != null ? 'School Announcements' : 'Announcements',
      onScrollNotification: _onScroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.schoolId == null) ...[
            _FiltersBar(controller: ctl),
            const SizedBox(height: 16),
          ],
          if (ctl.error != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ctl.error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: ctl.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (ctl.loading && ctl.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ctl.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No announcements to show.')),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctl.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final a = ctl.items[i];
                  return AnnouncementCard(
                    announcement: a,
                    onTap: () => context.go('/announcements/${a.id}'),
                  );
                },
              ),
            ),
          if (ctl.appending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!ctl.loading && !ctl.appending && ctl.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton(
                  onPressed: ctl.loadMore,
                  child: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FiltersBar extends ConsumerWidget {
  final AnnouncementsFeedController controller;
  const _FiltersBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (controller.canFollowedOnly)
                  FilterChip(
                    label: const Text('Followed schools only'),
                    selected: controller.followedOnly,
                    onSelected: (v) => controller.applyFilters(followedOnly: v),
                    selectedColor: theme.colorScheme.surfaceContainerHighest,
                    checkmarkColor: theme.colorScheme.onSurface,
                  ),
                _DropdownFilterChip<AnnouncementCategory>(
                  label: controller.category?.label() ?? 'Any category',
                  value: controller.category,
                  items: [
                    const PopupMenuItem(value: null, child: Text('Any category')),
                    ...AnnouncementCategory.values.map((category) =>
                      PopupMenuItem(value: category, child: Text(category.label()))),
                  ],
                  onChanged: (value) => controller.applyFilters(category: value),
                  theme: theme,
                ),
                _DropdownFilterChip<UrgencyLevel>(
                  label: controller.urgency?.label() ?? 'Any urgency',
                  value: controller.urgency,
                  items: [
                    const PopupMenuItem(value: null, child: Text('Any urgency')),
                    ...UrgencyLevel.values.map((urgency) =>
                      PopupMenuItem(value: urgency, child: Text(urgency.label()))),
                  ],
                  onChanged: (value) => controller.applyFilters(urgency: value),
                  theme: theme,
                ),
                _DropdownFilterChip<PublisherType>(
                  label: controller.publisherType?.label() ?? 'Any source',
                  value: controller.publisherType,
                  items: [
                    const PopupMenuItem(value: null, child: Text('Any source')),
                    ...PublisherType.values.map((type) =>
                      PopupMenuItem(value: type, child: Text(type.label()))),
                  ],
                  onChanged: (value) => controller.applyFilters(publisherType: value),
                  theme: theme,
                ),
                TextButton.icon(
                    onPressed: controller.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownFilterChip<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T?> onChanged;
  final ThemeData theme;

  const _DropdownFilterChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value != null;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        _showDropdown(context);
      },
      selectedColor: theme.colorScheme.surfaceContainerHighest,
      checkmarkColor: theme.colorScheme.onSurface,
      showCheckmark: false,
    );
  }

  void _showDropdown(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size size = button.size;

    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy + size.height + 200,
      ),
      items: items,
      initialValue: value,
    ).then((selected) {
      if (selected != null) {
        onChanged(selected);
      }
    });
  }
}

/// Reusable card to render one announcement summary. Used by both the
/// feed and the recent-announcements section on a school detail page.
class AnnouncementCard extends ConsumerWidget {
  final Announcement announcement;
  final VoidCallback? onTap;
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final a = announcement;
    final image = a.imgUrl;
    final user = ref.watch(authControllerProvider).user;

    return Card(
      clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null && image.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 7,
                      child: Image.network(
                        _absoluteImage(image),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                              child: Icon(Icons.image_not_supported_outlined)),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppBadge(
                          label: a.category.label(),
                          small: true,
                        ),
                        if (a.urgencyLevel != UrgencyLevel.normal)
                          AppBadge(
                            label: a.urgencyLevel.label(),
                            small: true,
                          ),
                        AppBadge(
                          icon: a.publisherType == PublisherType.moe
                              ? Icons.account_balance_outlined
                              : Icons.school_outlined,
                          label: a.school?.schoolName ?? a.publisherType.label(),
                          small: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatAnnouncementDateFeed(a.datePosted),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    // Action bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        LikeAction(
                          targetType: LikeTargetType.announcement,
                          targetId: a.id,
                        ),
                        ShareAction(
                          title: a.title,
                          content: a.content,
                          url: 'https://yourapp.com/announcements/${a.id}',
                        ),
                        IconButton(
                          icon: const Icon(Icons.flag_outlined),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => ReportDialog(
                              targetType: ReportTargetType.announcement,
                              targetId: a.id,
                            ),
                          ),
                          tooltip: 'Report',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

String _absoluteImage(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
  return '${AppConfig.apiBaseUrl}/$url';
}

String _formatAnnouncementDateFeed(dynamic dateInput) {
  DateTime d;
  if (dateInput is DateTime) {
    d = dateInput;
  } else if (dateInput is String) {
    d = DateTime.tryParse(dateInput) ?? DateTime.now();
  } else {
    return 'Unknown date';
  }
  
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _formatDate(dynamic dateInput) {
  DateTime d;
  if (dateInput is DateTime) {
    d = dateInput;
  } else if (dateInput is String) {
    d = DateTime.tryParse(dateInput) ?? DateTime.now();
  } else {
    return 'Unknown date';
  }
  
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
