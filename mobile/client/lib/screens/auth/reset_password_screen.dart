import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth.dart';
import '../../widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? phone;
  const ResetPasswordScreen({super.key, this.phone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _phone;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _phone = widget.phone;
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
        phone: _phone ?? '',
        otp: _otpController.text.trim(),
        newPassword: _passwordController.text.trim());
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe réinitialisé')));
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.error ?? 'Erreur lors de la réinitialisation')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialiser le mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Entrez le code reçu et choisissez un nouveau mot de passe',
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                      hintText: 'Code OTP',
                      prefixIcon: Icon(Icons.lock_clock_rounded)),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Entrez le code OTP' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      hintText: 'Nouveau mot de passe',
                      prefixIcon: Icon(Icons.lock_rounded)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Entrez un mot de passe';
                    if (v.length < 6)
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      hintText: 'Confirmer le mot de passe',
                      prefixIcon: Icon(Icons.lock_rounded)),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Confirmez le mot de passe';
                    if (v != _passwordController.text)
                      return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                    text: 'Réinitialiser',
                    isLoading: _isLoading,
                    onPressed: _reset,
                    gradient: AppTheme.primaryGradient),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
