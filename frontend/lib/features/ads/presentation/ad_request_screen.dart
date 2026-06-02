import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../../shared/utils/error_handler.dart';
import '../data/ad_dtos.dart';
import '../data/ad_repository.dart';

/// Public ad request — payment happens later via email link after moderator approval.
class AdRequestScreen extends ConsumerStatefulWidget {
  const AdRequestScreen({super.key});

  @override
  ConsumerState<AdRequestScreen> createState() => _AdRequestScreenState();
}

class _AdRequestScreenState extends ConsumerState<AdRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _urlCtl = TextEditingController();
  final _durationCtl = TextEditingController(text: '7');

  AdPlacementType _placement = AdPlacementType.banner;
  AdPricingInfo? _pricing;
  PlatformFile? _image;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _companyCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _titleCtl.dispose();
    _descCtl.dispose();
    _urlCtl.dispose();
    _durationCtl.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    try {
      final p = await ref.read(adRepositoryProvider).pricing();
      if (mounted) setState(() => _pricing = p);
    } catch (_) {}
  }

  int get _durationDays => int.tryParse(_durationCtl.text.trim()) ?? 0;

  double get _estimatedAmount {
    final rate = _pricing?.rates[_placement.toWire()] ?? 1000;
    return rate * _durationDays;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _image = result.files.first);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(adRepositoryProvider).submitRequest(
            companyName: _companyCtl.text.trim(),
            contactEmail: _emailCtl.text.trim(),
            contactPhone: _phoneCtl.text.trim(),
            title: _titleCtl.text.trim(),
            description: _descCtl.text.trim(),
            targetUrl: _urlCtl.text.trim(),
            durationDays: _durationDays,
            placementType: _placement,
            imageBytes: _image?.bytes,
            imageFilename: _image?.name,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Request submitted'),
          content: Text(
            'Thank you! A moderator will review your advertisement. '
            'If approved, payment instructions will be sent to '
            '${_emailCtl.text.trim()}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/');
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = ErrorHandler.getUserFriendlyMessage(e));
    } catch (e) {
      setState(() => _error = ErrorHandler.getUserFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Request an advertisement',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(
                        'Submit your ad for review. No payment is required now — after a moderator '
                        'approves your content, you will receive an email with the amount due and a '
                        'link to pay. Your ad goes live once payment is completed.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      TextFormField(
                        controller: _companyCtl,
                        decoration: const InputDecoration(
                          labelText: 'Company / organization',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 2) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailCtl,
                        decoration: const InputDecoration(
                          labelText: 'Contact email',
                          helperText: 'Payment instructions are sent here after approval',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneCtl,
                        decoration: const InputDecoration(
                          labelText: 'Contact phone',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            (v == null || v.trim().length < 9) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _titleCtl,
                        decoration: const InputDecoration(
                          labelText: 'Advertisement title',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descCtl,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _urlCtl,
                        decoration: const InputDecoration(
                          labelText: 'Target website URL',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final uri = Uri.tryParse(v.trim());
                          if (uri == null || !uri.hasScheme) return 'Enter a valid URL';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<AdPlacementType>(
                        value: _placement,
                        decoration: const InputDecoration(
                          labelText: 'Placement',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: AdPlacementType.values
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.label()),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _placement = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _durationCtl,
                        decoration: const InputDecoration(
                          labelText: 'Duration (days)',
                          helperText: 'Estimated total shown below (billed after approval)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final d = int.tryParse(v?.trim() ?? '');
                          if (d == null || d < 1 || d > 365) return 'Enter 1–365 days';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_pricing != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Estimated total after approval: ${_estimatedAmount.toStringAsFixed(0)} ETB',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(_image == null
                            ? 'Upload banner image (optional)'
                            : _image!.name),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _submitRequest,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit for review'),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.home_outlined, size: 16),
                        label: const Text('Back to home'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
