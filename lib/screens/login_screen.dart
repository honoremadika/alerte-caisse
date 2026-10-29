import 'package:flutter/material.dart';

import '../app.dart' show AppMode;
import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../services/desktop_overlay.dart';
import '../widgets/lang_menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.mode});
  final AppMode mode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _show = false;
  String? _error;

  Future<void> _submit() async {
    if (_login.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = tr('errFillAll'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().signIn(_login.text, _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        // Glisser cette barre pour déplacer la fenêtre (ordinateur).
        flexibleSpace: DesktopOverlay.dragArea(child: const SizedBox.expand()),
        actions: const [LangMenu()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: AutofillGroup(
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
                    controller: _login,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: tr('loginId'),
                      hintText: tr('loginIdHint'),
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_show,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: tr('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: tr('showPassword'),
                        icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _show = !_show),
                      ),
                      border: const OutlineInputBorder(),
                    ),
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
      ),
    );
  }
}
