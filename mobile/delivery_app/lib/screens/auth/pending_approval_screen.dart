import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_button.dart';

/// Shown to delivery accounts that are not (or no longer) verified by the
/// admin. They cannot access deliveries until approved.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isChecking = false;
  late final NotificationProvider _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationProvider>();
    // The admin's decision arrives as a notification: reload the account then
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifications.startPolling(
        onAccountChanged: () => _checkStatus(silent: true),
      );
    });
  }

  @override
  void dispose() {
    _notifications.stopPolling();
    super.dispose();
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    final authProvider = context.read<AuthProvider>();
    final stillLoggedIn = await authProvider.refreshProfile();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (!stillLoggedIn) {
      context.go('/login');
    } else if (authProvider.isApproved) {
      context.go('/dashboard');
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre compte est toujours en cours de vérification.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }
  }

  Future<void> _logout() async {
    _notifications.clear();
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isSuspended = user != null && !user.isActive;
    final rejectionReason = user?.rejectionReason;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuspended
                        ? Icons.block_rounded
                        : Icons.hourglass_top_rounded,
                    size: 56,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isSuspended
                    ? 'Compte suspendu'
                    : rejectionReason != null
                        ? 'Compte non validé'
                        : 'Vérification en cours',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isSuspended
                    ? 'Votre compte a été suspendu par l\'administrateur. Contactez le support pour plus d\'informations.'
                    : rejectionReason != null
                        ? 'Votre compte n\'a pas été validé.\nMotif : $rejectionReason\n\nContactez le support pour corriger vos informations.'
                        : 'Bonjour ${user?.name ?? ''}, votre compte livreur est en cours de vérification par notre équipe. Vous pourrez recevoir des livraisons dès qu\'il sera validé (24 à 48 heures). Cet écran se met à jour automatiquement.',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildStep(Icons.check_circle, 'Compte créé', true),
                    _buildStep(Icons.two_wheeler, 'Informations du véhicule envoyées', true),
                    _buildStep(Icons.verified_user, 'Validation par l\'administrateur',
                        user?.isApproved ?? false),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Vérifier le statut',
                gradient: AppTheme.primaryGradient,
                icon: Icons.refresh,
                isLoading: _isChecking,
                onPressed: () => _checkStatus(),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Se déconnecter',
                outlined: true,
                onPressed: _logout,
              ),
              const SizedBox(height: 24),
              Text(
                'Support: ${AppConfig.supportEmail}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(IconData icon, String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? icon : Icons.radio_button_unchecked,
            color: done ? AppTheme.successColor : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                color: done ? AppTheme.textPrimaryColor : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
