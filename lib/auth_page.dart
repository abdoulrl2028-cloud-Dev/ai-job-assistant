import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(_registering ? 'Criar conta' : 'Entrar', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Acesse suas candidaturas e assinatura em qualquer dispositivo.'),
                const SizedBox(height: 24),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                FilledButton(onPressed: _submitting ? null : _submit, child: Text(_registering ? 'Criar conta' : 'Entrar')),
                TextButton(onPressed: _submitting ? null : () => setState(() => _registering = !_registering), child: Text(_registering ? 'Ja tenho uma conta' : 'Criar uma conta')),
              ]),
            ),
          ),
        ),
      );

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um e-mail e uma senha com ao menos 6 caracteres.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_registering) {
        await widget.client.auth.signUp(email: _email.text.trim(), password: _password.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada. Confirme seu e-mail para continuar.')));
      } else {
        await widget.client.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}