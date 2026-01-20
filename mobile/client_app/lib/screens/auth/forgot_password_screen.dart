import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../config/theme.dart';
import '../../providers/auth.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _fullPhone = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final success = await auth.requestPasswordReset(phone: _fullPhone);

    setState(() => _isLoading = false);

    if (success) {
      // Navigate to reset screen, pass phone
      context.push('/reset-password', extra: {'phone': _fullPhone});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Erreur lors de la requête')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text('Entrez votre numéro de téléphone',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                IntlPhoneField(
                  controller: _phoneController,
                  initialCountryCode: 'TD',
                  decoration: const InputDecoration(
                      hintText: '600000000',
                      prefixIcon: Icon(Icons.phone_rounded)),
                  onChanged: (phone) => _fullPhone = phone.completeNumber,
                  validator: (value) {
                    if (value == null || value.number.isEmpty)
                      return 'Veuillez entrer votre numéro de téléphone';
                    if ((value.countryISOCode == 'TD' ||
                            value.countryISOCode == 'td') &&
                        value.number.length != 9) {
                      return 'Le numéro du Tchad doit contenir 9 chiffres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                    text: 'Envoyer le code',
                    isLoading: _isLoading,
                    onPressed: _requestReset,
                    gradient: AppTheme.primaryGradient),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
