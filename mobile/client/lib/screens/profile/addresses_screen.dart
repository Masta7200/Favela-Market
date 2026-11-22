import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/usermodel.dart';
import '../../providers/auth.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  static void _showResult(
    ScaffoldMessengerState messenger,
    AuthProvider auth,
    bool success,
    String message,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content:
            Text(success ? message : (auth.error ?? 'Une erreur est survenue')),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<void> _setDefault(BuildContext context, AddressModel address) async {
    if (address.id == null) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await auth.setDefaultAddress(address.id!);
    _showResult(messenger, auth, success, 'Adresse par défaut mise à jour');
  }

  Future<void> _confirmDelete(
      BuildContext context, AddressModel address) async {
    if (address.id == null) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Supprimer l'adresse"),
        content: Text(
            'Supprimer « ${address.label.isEmpty ? address.fullAddress : address.label} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final success = await auth.deleteAddress(address.id!);
    _showResult(messenger, auth, success, 'Adresse supprimée');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final addresses = authProvider.user?.addresses ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes adresses'),
      ),
      body: addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucune adresse enregistrée'),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajoutez une adresse de livraison',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/add-address'),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une adresse'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: address.isDefault
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: address.isDefault
                            ? Colors.white
                            : AppTheme.primaryColor,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          address.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Par défaut',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(address.fullAddress),
                        Text([
                          if (address.quarter != null &&
                              address.quarter!.isNotEmpty)
                            address.quarter!,
                          address.city,
                        ].join(', ')),
                        if (address.details != null &&
                            address.details!.isNotEmpty)
                          Text(
                            address.details!,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        if (!address.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline),
                                SizedBox(width: 8),
                                Text('Définir par défaut'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppTheme.errorColor),
                              SizedBox(width: 8),
                              Text('Supprimer',
                                  style: TextStyle(color: AppTheme.errorColor)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'default') {
                          _setDefault(context, address);
                        } else if (value == 'edit') {
                          context.push('/edit-address', extra: address);
                        } else if (value == 'delete') {
                          _confirmDelete(context, address);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/add-address'),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            )
          : null,
    );
  }
}
