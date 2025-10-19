import 'package:flutter/material.dart';

class DismissibleSetRow extends StatelessWidget {
  const DismissibleSetRow({
    required this.dismissibleKey,
    required this.child,
    required this.onRemove,
  });

  final Key dismissibleKey;
  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    return ClipRRect(
      borderRadius: radius,
      child: Dismissible(
        key: dismissibleKey,
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove(),
        background: const SizedBox.shrink(),
        secondaryBackground: _DismissBackground(radius: radius),
        dismissThresholds: const {DismissDirection.endToStart: 0.3},
        child: child,
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.radius});

  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: radius,
      ),
      child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
    );
  }
}
