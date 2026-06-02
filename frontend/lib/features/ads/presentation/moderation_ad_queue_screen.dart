import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../data/ad_dtos.dart';
import '../data/ad_repository.dart';

class ModerationAdQueueScreen extends ConsumerStatefulWidget {
  const ModerationAdQueueScreen({super.key});

  @override
  ConsumerState<ModerationAdQueueScreen> createState() =>
      _ModerationAdQueueScreenState();
}

class _ModerationAdQueueScreenState extends ConsumerState<ModerationAdQueueScreen> {
  bool _loading = false;
  String? _error;
  List<Advertisement> _items = const [];
  AdStatus _filter = AdStatus.pendingReview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(adRepositoryProvider).adminList(
            status: _filter,
            limit: 50,
          );
      setState(() => _items = result.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Advertisement ad) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve advertisement?'),
        content: Text(
          'Approve "${ad.title}" and email payment instructions to the advertiser? '
          'The ad will not go live until they pay.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve & email')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adRepositoryProvider).adminApprove(ad.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approved — payment email sent to advertiser'),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _reject(Advertisement ad) async {
    final reasonCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject advertisement'),
        content: TextField(
          controller: reasonCtl,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adRepositoryProvider).adminReject(
            ad.id,
            reason: reasonCtl.text.trim().isEmpty ? null : reasonCtl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advertisement rejected')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      reasonCtl.dispose();
    }
  }

  String _imageUrl(String? relative) {
    if (relative == null || relative.isEmpty) return '';
    if (relative.startsWith('http')) return relative;
    return '${AppConfig.apiBaseUrl}$relative';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveShell(
      title: 'Advertisement queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<AdStatus>(
            segments: const [
              ButtonSegment(
                value: AdStatus.pendingReview,
                label: Text('Review'),
              ),
              ButtonSegment(
                value: AdStatus.awaitingPayment,
                label: Text('Awaiting pay'),
              ),
              ButtonSegment(value: AdStatus.active, label: Text('Active')),
              ButtonSegment(value: AdStatus.rejected, label: Text('Rejected')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) {
              setState(() => _filter = s.first);
              _load();
            },
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_items.isEmpty)
            const Text('No advertisements in this queue.')
          else
            ..._items.map((ad) {
              final img = _imageUrl(ad.imageUrl);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad.title, style: theme.textTheme.titleLarge),
                      Text('${ad.companyName} · ${ad.contactEmail} · ${ad.contactPhone}'),
                      Text('${ad.placementType.label()} · ${ad.durationDays} days'),
                      if (ad.payment != null)
                        Text(
                          'Payment: ${ad.payment!.amount.toStringAsFixed(0)} ETB · '
                          '${ad.payment!.status ?? '—'} · '
                          '${ad.payment!.transactionId ?? 'no reference'}',
                        ),
                      if (img.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Image.network(img, height: 80, fit: BoxFit.cover),
                        ),
                      if (ad.description != null)
                        Text(ad.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      if (_filter == AdStatus.pendingReview)
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () => _approve(ad),
                              child: const Text('Approve'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _reject(ad),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/moderation'),
            child: const Text('Back to moderation'),
          ),
        ],
      ),
    );
  }
}
