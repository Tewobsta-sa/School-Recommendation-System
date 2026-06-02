import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../data/ad_dtos.dart';
import '../data/ad_repository.dart';

class AdPaymentScreen extends ConsumerStatefulWidget {
  final int adId;
  const AdPaymentScreen({super.key, required this.adId});

  @override
  ConsumerState<AdPaymentScreen> createState() => _AdPaymentScreenState();
}

class _AdPaymentScreenState extends ConsumerState<AdPaymentScreen> {
  bool _loading = true;
  bool _initiating = false;
  String? _error;
  Advertisement? _ad;
  double _amountDue = 0;
  String? _paymentUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(adRepositoryProvider).getForPayment(widget.adId);
      setState(() {
        _ad = result.advertisement;
        _amountDue = result.amountEtb;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _initiating = true;
      _error = null;
    });
    try {
      final url =
          await ref.read(adRepositoryProvider).initializePayment(widget.adId);
      setState(() => _paymentUrl = url);

      if (mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _initiating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ad = _ad;

    return ResponsiveShell(
      title: 'Complete payment',
      child: _loading && ad == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && ad == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/landing'),
                      child: const Text('Back to home'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ad != null) ...[
                      Text(ad.title, style: theme.textTheme.headlineSmall),
                      Text(
                          '${ad.companyName} · ${ad.placementType.label()} · ${ad.durationDays} days'),
                      const SizedBox(height: 8),
                      Text(
                        'Amount due: ${_amountDue.toStringAsFixed(0)} ETB',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You will be redirected to Chappa secure payment gateway to complete your payment.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!,
                            style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    FilledButton(
                      onPressed: (_initiating || _paymentUrl != null)
                          ? null
                          : _initiatePayment,
                      child: _initiating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Pay with Chappa'),
                    ),
                    if (_paymentUrl != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Payment initiated. If you were not redirected, click the link below:',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          final uri = Uri.parse(_paymentUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text('Open payment page'),
                      ),
                    ],
                  ],
                ),
    );
  }
}
