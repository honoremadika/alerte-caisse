import 'package:flutter/material.dart';

import '../app.dart' show AppMode;
import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../widgets/lang_menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.mode});
  final AppMode mode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().signIn(_email.text, _password.text);
    } catch (e) {
      setState(() => _error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(actions: const [LangMenu()]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                    widget.mode == AppMode.caisse
                        ? Icons.point_of_sale
                        : Icons.notifications_active,
                    size: 56,
                    color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                    widget.mode == AppMode.caisse
                        ? tr('appCaisseTitle')
                        : tr('appManagerTitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: tr('email'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                      labelText: tr('password'),
                      border: const OutlineInputBorder()),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(tr('signIn')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
