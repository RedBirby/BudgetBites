import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';

class LocationGate extends ConsumerStatefulWidget {
  const LocationGate({this.onCompleted, super.key});

  final VoidCallback? onCompleted;

  @override
  ConsumerState<LocationGate> createState() => _LocationGateState();
}

class _LocationGateState extends ConsumerState<LocationGate> {
  final _zip = TextEditingController();
  bool _confirmed = false;
  @override
  void dispose() {
    _zip.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _confirmed = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _confirmed = true);
      final onCompleted = widget.onCompleted;
      if (onCompleted != null) {
        // Keep the confirmation visible long enough to reassure the user
        // that the location lookup completed before returning to the app.
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (mounted) onCompleted();
        });
      }
    } catch (_) {
      // The controller stores the user-facing data error in AppState so the
      // screen stays focused on rendering rather than fetching data.
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(
      appControllerProvider.select((state) => state.loadingStores),
    );
    final error = ref.watch(
      appControllerProvider.select((state) => state.storeError),
    );
    final controller = ref.read(appControllerProvider.notifier);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.mint,
                  foregroundColor: AppColors.green,
                  child: Icon(Icons.location_on_outlined, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  'Find stores near you',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 7),
                const Text(
                  'Enter the shopping-area ZIP or use your device location before building the grocery plan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                const HelpfulHint(
                  text:
                      'Tip: enter a ZIP code if location permission is off. We use it to find nearby stores.',
                ),
                if (_confirmed) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Location received. Finding nearby grocery stores…',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _zip,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  onSubmitted: (_) =>
                      _run(() => controller.locateByZip(_zip.text.trim())),
                  decoration: const InputDecoration(
                    labelText: 'ZIP code',
                    counterText: '',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: loading
                      ? null
                      : () => _run(
                          () => controller.locateByZip(_zip.text.trim()),
                        ),
                  icon: const Icon(Icons.search),
                  label: const Text('Search ZIP'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () => _run(controller.useCurrentLocation),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my current location'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Approximate location is used only to find nearby stores. Exact coordinates are not persisted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
