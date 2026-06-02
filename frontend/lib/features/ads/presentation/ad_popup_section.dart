import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config.dart';
import '../../auth/data/auth_repository.dart';
import '../data/ad_dtos.dart';
import '../data/ad_repository.dart';

class AdPopupSection extends ConsumerStatefulWidget {
  const AdPopupSection({super.key});

  @override
  ConsumerState<AdPopupSection> createState() => _AdPopupSectionState();
}

class _AdPopupSectionState extends ConsumerState<AdPopupSection> {
  Advertisement? _popupAd;
  bool _impressionSent = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _loadPopupAd();
  }

  Future<void> _loadPopupAd() async {
    try {
      final ads = await ref.read(adRepositoryProvider).listActive(
            placement: AdPlacementType.popup,
            limit: 1,
          );
      if (!mounted) return;
      if (ads.isNotEmpty) {
        setState(() {
          _popupAd = ads.first;
          _visible = true;
        });
        if (!_impressionSent) {
          _impressionSent = true;
          ref.read(adRepositoryProvider).recordImpression(ads.first.id);
        }
      }
    } catch (_) {
      // Silently fail - popup ads are optional
    }
  }

  Future<void> _onTap() async {
    if (_popupAd == null) return;
    try {
      await ref.read(adRepositoryProvider).recordClick(_popupAd!.id);
    } catch (_) {}
    final uri = Uri.tryParse(_popupAd!.targetUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    setState(() => _visible = false);
  }

  String _imageUrl(String? relative) {
    if (relative == null || relative.isEmpty) return '';
    if (relative.startsWith('http')) return relative;
    return '${AppConfig.apiBaseUrl}$relative';
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _popupAd == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final img = _imageUrl(_popupAd!.imageUrl);

    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (img.isNotEmpty)
                  Expanded(
                    child: Image.network(
                      img,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported, size: 64),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_popupAd!.title, style: theme.textTheme.titleLarge),
                      if (_popupAd!.description != null &&
                          _popupAd!.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _popupAd!.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _visible = false),
                            child: const Text('Close'),
                          ),
                          FilledButton(
                            onPressed: _onTap,
                            child: const Text('Visit Site'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => setState(() => _visible = false),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
