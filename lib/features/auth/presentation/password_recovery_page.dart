import 'package:flutter/material.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;

  String? _errorText;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Define una nueva password para tu cuenta.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const <String>[AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Nueva password',
                  hintText: 'Minimo 8 caracteres',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                autofillHints: const <String>[AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Confirmar password',
                  hintText: 'Repite la nueva password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: _errorText == null
                    ? const SizedBox(height: 0)
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _errorText!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.lock_reset),
                label: const Text('Actualizar password'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final password = _passwordController.text;
    final confirmation = _confirmController.text;

    if (password.length < 8) {
      setState(() {
        _errorText = 'La password debe tener al menos 8 caracteres.';
      });
      return;
    }

    if (password != confirmation) {
      setState(() {
        _errorText = 'Las passwords no coinciden.';
      });
      return;
    }

    Navigator.of(context).pop(password);
  }
}
