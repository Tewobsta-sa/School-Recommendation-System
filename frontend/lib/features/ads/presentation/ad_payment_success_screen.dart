import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
  
import '../../../shared/widgets/responsive_shell.dart';  
import '../../auth/data/auth_repository.dart';  
import '../data/ad_dtos.dart';  
import '../data/ad_repository.dart';  
  
class AdPaymentSuccessScreen extends ConsumerStatefulWidget {  
  final int adId;  
  const AdPaymentSuccessScreen({super.key, required this.adId});  
  
  @override  
  ConsumerState<AdPaymentSuccessScreen> createState() => _AdPaymentSuccessScreenState();  
}  
  
class _AdPaymentSuccessScreenState extends ConsumerState<AdPaymentSuccessScreen> {  
  bool _loading = true;  
  Advertisement? _ad;  
  
  @override  
  void initState() {  
    super.initState();  
    _checkStatus();  
  }  
  
  Future<void> _checkStatus() async {  
    try {  
      final ad = await ref.read(adRepositoryProvider).verifyPaymentStatus(widget.adId);  
      if (mounted) {  
        setState(() {  
          _ad = ad;  
          _loading = false;  
        });  
      }  
    } catch (_) {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
  
    return ResponsiveShell(  
      title: 'Payment Status',  
      child: _loading  
          ? const Center(child: CircularProgressIndicator())  
          : Column(  
              crossAxisAlignment: CrossAxisAlignment.stretch,  
              children: [  
                Icon(  
                  _ad?.status == AdStatus.active  
                      ? Icons.check_circle  
                      : Icons.info,  
                  size: 64,  
                  color: _ad?.status == AdStatus.active  
                      ? Colors.green  
                      : theme.colorScheme.primary,  
                ),  
                const SizedBox(height: 24),  
                Text(  
                  _ad?.status == AdStatus.active  
                      ? 'Payment Successful!'  
                      : 'Payment Processing',  
                  style: theme.textTheme.headlineSmall,  
                  textAlign: TextAlign.center,  
                ),  
                const SizedBox(height: 16),  
                Text(  
                  _ad?.status == AdStatus.active  
                      ? 'Your advertisement is now live on the platform.'  
                      : 'Your payment is being processed. Your ad will go live shortly.',  
                  style: theme.textTheme.bodyMedium,  
                  textAlign: TextAlign.center,  
                ),  
                const SizedBox(height: 32),  
                FilledButton(  
                  onPressed: () => context.go('/landing'),  
                  child: const Text('Return to Home'),  
                ),  
              ],  
            ),  
    );  
  }  
}