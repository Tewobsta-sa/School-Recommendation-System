import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/error_handler.dart';
import '../../../shared/utils/message_helper.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/password_field.dart';
import '../state/auth_controller.dart';
import '../data/auth_repository.dart' show ApiException;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isSelfDeactivated = false;
  bool _isAccountBanned = false;
  bool _identifierKind = false; // false = email, true = phone

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return null; // Don't show error for empty during interaction
  return EmailValidator.validate(v) ? null : 'Invalid email';
}

String? _validatePhone(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return null; // Don't show error for empty during interaction
  if (v.length != 9) {
    return 'Please enter a valid phone number';
  }
  if (!v.startsWith('9') && !v.startsWith('7')) {
    return 'Please enter a valid phone number';
  }
  return null;
}

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final identifier = _identifierKind
          ? '+251${_phone.text.trim()}'
          : _email.text.trim();

      await ref
          .read(authControllerProvider)
          .login(identifier, _password.text);

      // Show success message
      if (mounted) {
        MessageHelper.showSuccess(context, SuccessMessages.login);
      }
      // Router redirect handles navigation.
    } catch (e) {
      if (e is ApiException && e.code == 'PHONE_NOT_VERIFIED') {
        if (mounted) {
          MessageHelper.showInfo(context, 'Please verify your phone number to continue.');
          final phone = _identifierKind ? _phone.text.trim() : _email.text.trim();
          context.go(
            '/verify-phone?phone=${Uri.encodeComponent(phone)}',
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _error = ErrorHandler.getUserFriendlyMessage(e);
          _isSelfDeactivated =
              (e is ApiException && e.code == 'ACCOUNT_SELF_DEACTIVATED');
          _isAccountBanned =
              (e is ApiException && e.code == 'ACCOUNT_BANNED');
        });
      }
    } finally {
      if (mounted && context.mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Welcome back',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Email'),
                            icon: Icon(Icons.mail_outline),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Phone'),
                            icon: Icon(Icons.phone_outlined),
                          ),
                        ],
                        selected: {_identifierKind},
                        onSelectionChanged: (s) =>
                            setState(() => _identifierKind = s.first),
                      ),
                      const SizedBox(height: 10),
                      if (!_identifierKind)
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'example@gmail.com',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: _validateEmail,
                        )
                      else
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixText: '+251',
                            helperText: 'Add your phone number',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: _validatePhone,
                        ),
                      const SizedBox(height: 10),
                      PasswordField(
                        controller: _password,
                        labelText: 'Password',
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return null; // Don't show error for empty during interaction
                          return t.length >= 6 ? null : 'At least 6 characters';
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 6),
                        Text(_error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        if (_isSelfDeactivated && !_isAccountBanned) ...[
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () => _showReactivateDialog(context),
                            child: const Text('Reactivate Account'),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      LoadingButton(
                        loading: _loading,
                        onPressed: _submit,
                        child: const Text('Sign in'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Create one'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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

  void _showReactivateDialog(BuildContext context) {
    final identifierController = TextEditingController(
      text: _identifierKind ? '+251${_phone.text}' : _email.text,
    );
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: identifierController,
              decoration: const InputDecoration(labelText: 'Email or phone'),
            ),
            PasswordField(
              controller: passwordController,
              labelText: 'Password',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(authControllerProvider).reactivate(
                      identifierController.text,
                      passwordController.text,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  MessageHelper.showSuccess(context, SuccessMessages.accountReactivated);
                  context.go('/');
                }
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(context, ErrorHandler.getUserFriendlyMessage(e));
                }
              }
            },
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }
}
