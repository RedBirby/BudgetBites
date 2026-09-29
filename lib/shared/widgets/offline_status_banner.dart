import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/connectivity_service.dart';

/// Keeps a clear, non-dismissible offline notice above every app route.
///
/// The notice is intentionally informational rather than a hard lock: saved
/// plans and cached data can still be useful while offline, while actions that
/// need a network continue to show their own retry guidance.
class OfflineStatusBanner extends StatefulWidget {
  const OfflineStatusBanner({required this.child, super.key});

  final Widget child;

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  final _connectivity = ConnectivityService();
  Timer? _poller;
  bool? _online;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshStatus(),
    );
  }

  Future<void> _refreshStatus() async {
    final online = await _connectivity.isOnline();
    if (!mounted || online == _online) return;
    setState(() => _online = online);
  }

  @override
  void dispose() {
    _poller?.cancel();
    _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_online == false)
        const SafeArea(top: true, bottom: false, child: _OfflineNotice()),
      Expanded(child: widget.child),
    ],
  );
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: 'Offline mode notice',
    child: Material(
      color: const Color(0xFFFFF4E5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 21,
                color: Color(0xFF8A4B08),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'You’re offline. ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(
                      text:
                          'Some BudgetBite features need an internet connection, '
                          'including live recipes, maps, store search, and sign-in. '
                          'Saved plans may still be available.',
                    ),
                  ],
                ),
                style: const TextStyle(
                  color: Color(0xFF6C3A08),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
