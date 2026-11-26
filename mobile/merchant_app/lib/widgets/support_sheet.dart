import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../config/theme.dart';

/// "Aide & Support": contact the team (call, WhatsApp, email) and FAQ.
Future<void> showSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const SupportSheet(),
  );
}

class _Faq {
  final String question;
  final String answer;

  const _Faq(this.question, this.answer);
}

const _faqs = <_Faq>[
  _Faq(
    'Pourquoi mon compte est-il en attente ?',
    'L\'équipe Tumaï Market vérifie chaque boutique avant son ouverture. Vous recevez une notification dès que votre compte est validé.',
  ),
  _Faq(
    'Pourquoi mon produit n\'est-il pas visible ?',
    'Les nouveaux produits, et les changements de nom, description, prix, photos ou catégorie, sont vérifiés avant d\'être publiés. Les changements de stock sont immédiats.',
  ),
  _Faq(
    'Mon produit a été refusé',
    'Le motif est indiqué dans la notification. Corrigez le produit puis enregistrez-le : il sera vérifié à nouveau.',
  ),
  _Faq(
    'Comment traiter une commande ?',
    'Confirmez la commande, puis passez-la « En préparation » et « Prête ». Un livreur assigné par Tumaï Market vient la récupérer.',
  ),
];

class SupportSheet extends StatelessWidget {
  const SupportSheet({super.key});

  /// Phone number with only digits and the leading "+"
  static String get _phone =>
      AppConfig.supportPhone.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _open(BuildContext context, Uri uri, String error) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Falls through to the error message
    }
    messenger.showSnackBar(
      SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Aide & Support',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Une question ou un problème ? Contactez notre équipe.',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 16),
          _ContactTile(
            icon: Icons.phone,
            title: 'Appeler',
            subtitle: AppConfig.supportPhone,
            onTap: () => _open(
              context,
              Uri(scheme: 'tel', path: _phone),
              'Impossible de lancer l\'appel',
            ),
          ),
          _ContactTile(
            icon: Icons.chat,
            title: 'WhatsApp',
            subtitle: AppConfig.supportPhone,
            onTap: () => _open(
              context,
              Uri.parse('https://wa.me/${_phone.replaceAll('+', '')}'),
              'Impossible d\'ouvrir WhatsApp',
            ),
          ),
          _ContactTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: AppConfig.supportEmail,
            onTap: () => _open(
              context,
              Uri(
                scheme: 'mailto',
                path: AppConfig.supportEmail,
                query: 'subject=${Uri.encodeComponent(AppConfig.appName)}',
              ),
              'Aucune application email trouvée',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Questions fréquentes',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final faq in _faqs)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                title: Text(
                  faq.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq.answer,
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
