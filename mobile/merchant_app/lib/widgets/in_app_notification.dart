import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// Shows notifications as a banner at the top of the app while it is open.
///
/// Wrap the app once (MaterialApp.router `builder`), then call
/// [InAppNotificationHost.show] from anywhere.
class InAppNotificationHost extends StatefulWidget {
  final Widget child;

  const InAppNotificationHost({super.key, required this.child});

  static _InAppNotificationHostState? _state;

  /// Queues a banner. [onTap] runs when the user taps it.
  static void show({
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color color = AppTheme.primaryColor,
    VoidCallback? onTap,
  }) {
    _state?._enqueue(_Banner(title, message, icon, color, onTap));
  }

  @override
  State<InAppNotificationHost> createState() => _InAppNotificationHostState();
}

class _Banner {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _Banner(this.title, this.message, this.icon, this.color, this.onTap);
}

class _InAppNotificationHostState extends State<InAppNotificationHost> {
  static const _displayTime = Duration(seconds: 5);

  final List<_Banner> _queue = [];
  _Banner? _current;
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    InAppNotificationHost._state = this;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (InAppNotificationHost._state == this) InAppNotificationHost._state = null;
    super.dispose();
  }

  void _enqueue(_Banner banner) {
    _queue.add(banner);
    if (_current == null) _next();
  }

  void _next() {
    if (_queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _current = _queue.removeAt(0);
      _visible = true;
    });
    _timer?.cancel();
    _timer = Timer(_displayTime, _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    if (!mounted || !_visible) return;
    setState(() => _visible = false);
    // Let the slide-out animation finish before showing the next one
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final banner = _current;
    return Stack(
      children: [
        widget.child,
        if (banner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -1.5),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Dismissible(
                    key: ObjectKey(banner),
                    direction: DismissDirection.up,
                    onDismissed: (_) {
                      _timer?.cancel();
                      _visible = false;
                      _next();
                    },
                    child: _BannerCard(
                      banner: banner,
                      onTap: () {
                        _dismiss();
                        banner.onTap?.call();
                      },
                      onClose: _dismiss,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _Banner banner;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _BannerCard({
    required this.banner,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: banner.color, width: 5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: banner.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(banner.icon, color: banner.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      banner.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
