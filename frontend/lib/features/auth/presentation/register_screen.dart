import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/error_handler.dart';
import '../../../shared/utils/message_helper.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/password_field.dart';
import '../data/auth_dtos.dart';
import '../data/auth_repository.dart';
import '../state/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

/// Whether the user is signing up with an email-as-credential (legacy path,
/// gated by a verification email) or a phone-as-credential (no verification,
/// usable immediately). Backend supports both.
enum _IdentifierKind { email, phone }

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  // MoE / Moderator accounts are admin-created per the spec, so the public
  // self-registration form only exposes the two consumer roles.
  UserRole _role = UserRole.parent;
  _IdentifierKind _identifierKind = _IdentifierKind.email;
  bool _loading = false;
  String? _error;
  bool _success = false;
  bool _resending = false;
  String? _resendMessage;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Only send the credential that matches the current toggle. The "other"
      // field is hidden from the form, so sending it would be lying to the
      // backend's uniqueness checks.
      final isEmail = _identifierKind == _IdentifierKind.email;
      final phoneValue = !isEmail && _phone.text.trim().isNotEmpty
          ? '+251${_phone.text.trim()}'
          : null;
      await ref.read(authControllerProvider).register(
            fullName: _name.text.trim(),
            email: isEmail ? _email.text.trim() : null,
            phone: phoneValue,
            password: _password.text,
            role: _role,
          );
      if (mounted) {
        setState(() => _success = true);
        MessageHelper.showSuccess(context, SuccessMessages.register);
      }
    } catch (e) {
      if (mounted) setState(() => _error = ErrorHandler.getUserFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _resending = true;
      _resendMessage = null;
    });
    try {
      final isEmail = _identifierKind == _IdentifierKind.email;
      if (isEmail) {
        await ref.read(authRepositoryProvider).resendVerification(_email.text.trim());
      } else {
        await ref.read(authRepositoryProvider).resendPhoneVerification('+251${_phone.text.trim()}');
      }
      if (mounted) {
        setState(() => _resendMessage = 'New verification sent!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _resendMessage = ErrorHandler.getUserFriendlyMessage(e));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      final isEmail = _identifierKind == _IdentifierKind.email;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        isEmail ? Icons.mark_email_read : Icons.sms_outlined,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEmail
                            ? "We sent a verification link to ${_email.text.trim()}."
                            : "We sent a verification code to +251${_phone.text.trim()}.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEmail
                            ? "Click the link to activate your account, then come back here to sign in."
                            : "Enter the SMS verification code to activate your account.",
                        textAlign: TextAlign.center,
                      ),
                      if (_resendMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _resendMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _resendMessage == 'New verification sent!'
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          if (isEmail) {
                            context.go('/login');
                          } else {
                            context.go(
                              '/verify-phone?phone=${Uri.encodeComponent(_phone.text.trim())}',
                            );
                          }
                        },
                        child: Text(
                          isEmail ? 'Back to sign in' : 'Verify phone',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: _resending
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: _resendVerification,
                                child: Text(
                                  isEmail
                                      ? "Didn't get the email? Resend verification link"
                                      : "Didn't get the SMS? Resend verification code",
                                ),
                              ),
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
      );
    }

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
                      Text('Create account',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (v) => (v ?? '').trim().isNotEmpty ? null : 'Required',
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<_IdentifierKind>(
                        segments: const [
                          ButtonSegment(
                            value: _IdentifierKind.email,
                            label: Text('Email'),
                            icon: Icon(Icons.mail_outline),
                          ),
                          ButtonSegment(
                            value: _IdentifierKind.phone,
                            label: Text('Phone'),
                            icon: Icon(Icons.phone_outlined),
                          ),
                        ],
                        selected: {_identifierKind},
                        onSelectionChanged: (s) =>
                            setState(() => _identifierKind = s.first),
                      ),
                      const SizedBox(height: 10),
                      if (_identifierKind == _IdentifierKind.email)
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'example@gmail.com',
                            helperText: "We'll send a verification link to this address.",
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return null; // Don't show error for empty
                            return EmailValidator.validate(t) ? null : 'Invalid email';
                          },
                        )
                      else
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixText: '+251',
                            helperText: 'Add your phone number (optional)',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return null; // Don't show error for empty
                            if (t.length != 9) {
                              return 'Please enter a valid phone number';
                            }
                            if (!t.startsWith('9') && !t.startsWith('7')) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 10),
                      PasswordField(
                        controller: _password,
                        labelText: 'Password',
                        helperText: 'Minimum 6 characters',
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return null; // Don't show error for empty
                          return t.length >= 6 ? null : 'At least 6 characters';
                        },
                      ),
                      const SizedBox(height: 10),
                      PasswordField(
                        controller: _confirmPassword,
                        labelText: 'Confirm password',
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (v) {
                          if (v != _password.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<UserRole>(
                        initialValue: _role,
                        decoration: const InputDecoration(
                          labelText: 'I am a…',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: UserRole.parent, child: Text('Parent')),
                          DropdownMenuItem(
                              value: UserRole.schoolAdmin,
                              child: Text('School administrator')),
                        ],
                        onChanged: (v) => setState(() => _role = v ?? UserRole.parent),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 12),
                      LoadingButton(
                        loading: _loading,
                        onPressed: _submit,
                        child: const Text('Create account'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Sign in'),
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
}
