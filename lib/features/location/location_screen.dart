import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/common_widgets.dart';
import '../plan/location_gate.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Shopping location')),
    body: PageContainer(
      child: LocationGate(
        onCompleted: () =>
            context.canPop() ? context.pop() : context.go('/discover'),
      ),
    ),
  );
}
