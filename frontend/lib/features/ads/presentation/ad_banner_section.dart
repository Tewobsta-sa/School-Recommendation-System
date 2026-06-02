import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config.dart';
import '../../auth/data/auth_repository.dart';
import '../data/ad_dtos.dart';
import '../data/ad_repository.dart';

/// Fetches and displays active ads for a placement; records impressions once.
class AdBannerSection extends ConsumerStatefulWidget {
  final AdPlacementType placement;
  final int limit;

  const AdBannerSection({
    super.key,
    this.placement = AdPlacementType.banner,
    this.limit = 3,
  });

  @override
  ConsumerState<AdBannerSection> createState() => _AdBannerSectionState();
}

class _AdBannerSectionState extends ConsumerState<AdBannerSection> {
  List<Advertisement>? _ads;
  final Set<int> _impressionSent = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ads = await ref.read(adRepositoryProvider).listActive(
            placement: widget.placement,
            limit: widget.limit,
          );
      if (!mounted) return;
      setState(() => _ads = ads);
      for (final ad in ads) {
        if (_impressionSent.add(ad.id)) {
          ref.read(adRepositoryProvider).recordImpression(ad.id);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _ads = const []);
    }
  }

  Future<void> _onTap(Advertisement ad) async {
    try {
      await ref.read(adRepositoryProvider).recordClick(ad.id);
    } catch (_) {}
    final uri = Uri.tryParse(ad.targetUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _imageUrl(String? relative) {
    if (relative == null || relative.isEmpty) return '';
    if (relative.startsWith('http')) return relative;
    return '${AppConfig.apiBaseUrl}$relative';
  }

  @override
  Widget build(BuildContext context) {
    final ads = _ads;
    if (ads == null || ads.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Sponsored',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        ...ads.map((ad) {
          final img = _imageUrl(ad.imageUrl);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _onTap(ad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (img.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 3 / 1,
                      child: Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ad.title, style: theme.textTheme.titleMedium),
                        if (ad.description != null &&
                            ad.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              ad.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          ad.companyName,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
