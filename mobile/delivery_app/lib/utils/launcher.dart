import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

Future<void> _launch(BuildContext context, Uri uri, String errorMessage) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
  } catch (_) {
    // Falls through to the error message
  }
  messenger.showSnackBar(
    SnackBar(content: Text(errorMessage), backgroundColor: AppTheme.errorColor),
  );
}

Future<void> callPhone(BuildContext context, String phone) =>
    _launch(context, Uri(scheme: 'tel', path: phone),
        'Impossible de lancer l\'appel');

Future<void> sendSms(BuildContext context, String phone) =>
    _launch(context, Uri(scheme: 'sms', path: phone),
        'Impossible d\'ouvrir les messages');

Future<void> openMaps(BuildContext context, String address) => _launch(
      context,
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      ),
      'Impossible d\'ouvrir la carte',
    );
