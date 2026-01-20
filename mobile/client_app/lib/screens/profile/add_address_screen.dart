import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth.dart';
import '../../models/usermodel.dart';
import '../../widgets/custom_button.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _quarterController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _labelController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _quarterController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _addAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    final address = AddressModel(
      label: _labelController.text.trim(),
      fullAddress: _fullAddressController.text.trim(),
      city: _cityController.text.trim(),
      quarter: _quarterController.text.trim(),
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      isDefault: _isDefault,
    );

    final success = await authProvider.addAddress(address);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse ajoutée avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Erreur lors de l\'ajout'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final hasAddresses = authProvider.user?.addresses?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une adresse'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                'Libellé',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Maison, Bureau, etc.',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un libellé';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Full Address
              Text(
                'Adresse complète *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullAddressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ex: 123 Rue Example, près du marché',
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer l\'adresse';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // City
              Text(
                'Ville *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Douala, Yaoundé',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer la ville';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Quarter
              Text(
                'Quartier',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quarterController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Bonapriso, Akwa',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 20),

              // Additional Details
              Text(
                'Instructions supplémentaires (optionnel)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ex: Bâtiment bleu, 2ème étage, porte à gauche',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),

              const SizedBox(height: 24),

              // Set as Default
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  title: const Text('Définir comme adresse par défaut'),
                  subtitle: hasAddresses
                      ? const Text(
                          'Cette adresse sera utilisée par défaut pour vos commandes',
                          style: TextStyle(fontSize: 12),
                        )
                      : null,
                  value: hasAddresses ? _isDefault : true,
                  onChanged: hasAddresses
                      ? (value) {
                          setState(() => _isDefault = value ?? false);
                        }
                      : null,
                  activeColor: AppTheme.primaryColor,
                ),
              ),

              if (!hasAddresses)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 16),
                  child: Text(
                    'Première adresse sera définie par défaut automatiquement',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Enregistrer l\'adresse',
                gradient: AppTheme.primaryGradient,
                icon: Icons.check,
                isLoading: _isLoading,
                onPressed: _addAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
