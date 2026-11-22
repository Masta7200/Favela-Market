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
    'Comment passer une commande ?',
    'Ajoutez des produits au panier puis validez avec votre adresse de livraison. Si le panier contient des produits de plusieurs boutiques, une commande est créée pour chaque boutique.',
  ),
  _Faq(
    'Comment payer ?',
    'Le paiement se fait en espèces à la livraison, auprès du livreur.',
  ),
  _Faq(
    'Comment suivre ma commande ?',
    'Ouvrez « Mes commandes ». Vous recevez aussi une notification quand votre commande est en route, puis livrée.',
  ),
  _Faq(
    'Puis-je annuler une commande ?',
    'Oui, depuis le détail de la commande, tant qu\'elle n\'est pas encore en cours de livraison.',
  ),
  _Faq(
    'J\'ai oublié mon mot de passe',
    'Sur l\'écran de connexion, touchez « Mot de passe oublié » : un code vous est envoyé par email.',
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
