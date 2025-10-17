import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session/demo_data.dart';
import '../../domain/session/models.dart';
import '../../domain/session/session_draft_notifier.dart';
import '../../domain/session/session_template.dart';
import '../summary/summary_screen.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key, required this.template});

  final SessionTemplate template;

  static const routeName = '/log';

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sessionDraftProvider.notifier).loadFromTemplate(widget.template);
    });
  }

  void _viewSummary(BuildContext context) {
    Navigator.of(context).pushNamed(SummaryScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(sessionDraftProvider);
    final notifier = ref.read(sessionDraftProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.template.name),
            Text(
              'Logging ${widget.template.mainExercise.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _MainLiftCard(
                      draft: draft,
                      onSelectLift: () => _showMainLiftSelector(context),
                      onClearLift: notifier.clearMainLift,
                      onRemoveSet: notifier.removeMainLiftSet,
                    ),
                    const SizedBox(height: 24),
                    _SupportExercisesCard(draft: draft),
                    const SizedBox(height: 24),
                    _SessionMetricsRow(draft: draft),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: draft.mainLift == null
                    ? null
                    : () => _showAddMainSetDialog(context, notifier),
                icon: const Icon(Icons.add),
                label: const Text('Add Main Lift Set'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _viewSummary(context),
                child: const Text('Review Summary'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMainLiftSelector(BuildContext context) async {
    final notifier = ref.read(sessionDraftProvider.notifier);
    final draft = ref.read(sessionDraftProvider);

    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            const ListTile(
              title: Text('Select main lift'),
              subtitle: Text('Exercise picker coming soon.'),
            ),
            for (final exercise in demoMainLifts)
              RadioListTile<String>(
                value: exercise.id,
                groupValue: draft.mainLift?.id,
                title: Text(exercise.name),
                subtitle: Text(exercise.category),
                onChanged: (_) => Navigator.of(context).pop(exercise),
              ),
          ],
        );
      },
    );

    if (selected != null) {
      notifier.setMainLift(selected);
    }
  }

  Future<void> _showAddMainSetDialog(
    BuildContext context,
    SessionDraftNotifier notifier,
  ) async {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController();
    final repsController = TextEditingController();
    final rirController = TextEditingController();

    final result = await showDialog<LiftSet>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Main Lift Set'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid weight';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter reps';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: rirController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'RIR (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final weight = double.parse(weightController.text);
                final reps = int.parse(repsController.text);
                final rir = int.tryParse(rirController.text);
                Navigator.of(
                  context,
                ).pop(LiftSet(weightKg: weight, reps: reps, rir: rir));
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      weightController.dispose();
      repsController.dispose();
      rirController.dispose();
    });

    if (result != null) {
      notifier.addMainLiftSet(result);
    }
  }
}

class _MainLiftCard extends StatelessWidget {
  const _MainLiftCard({
    required this.draft,
    required this.onSelectLift,
    required this.onClearLift,
    required this.onRemoveSet,
  });

  final SessionDraft draft;
  final VoidCallback onSelectLift;
  final VoidCallback onClearLift;
  final void Function(int) onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final hasLift = draft.mainLift != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(hasLift ? draft.mainLift!.name : 'Select lift'),
              subtitle: Text(
                hasLift
                    ? 'Sets logged: ${draft.mainLiftSets.length}'
                    : 'Exercise picker coming soon.',
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: onSelectLift,
            ),
            if (hasLift)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onClearLift,
                    icon: const Icon(Icons.close),
                    label: const Text('Clear main lift'),
                  ),
                ),
              ),
            if (draft.mainLiftSets.isNotEmpty) const Divider(),
            if (draft.mainLiftSets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Main lift sets',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final set = draft.mainLiftSets[index];
                        return ListTile(
                          title: Text('${set.weightKg} kg × ${set.reps}'),
                          subtitle: set.rir != null
                              ? Text('RIR: ${set.rir}')
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => onRemoveSet(index),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: draft.mainLiftSets.length,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SupportExercisesCard extends StatelessWidget {
  const _SupportExercisesCard({required this.draft});

  final SessionDraft draft;

  @override
  Widget build(BuildContext context) {
    final subtitle = draft.supports.isEmpty
        ? 'No support work logged yet.'
        : '${draft.supports.length} exercise(s)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Support Exercises'),
              subtitle: Text('$subtitle\nSupport picker coming soon.'),
              isThreeLine: true,
            ),
            if (draft.supports.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: draft.supports.length,
                itemBuilder: (context, index) {
                  final entry = draft.supports[index];
                  final volume = entry.volumeKg.toStringAsFixed(0);
                  return ListTile(
                    title: Text(entry.exercise.name),
                    subtitle: Text('${entry.sets.length} sets · $volume kg'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionMetricsRow extends StatelessWidget {
  const _SessionMetricsRow({required this.draft});

  final SessionDraft draft;

  @override
  Widget build(BuildContext context) {
    final e1rm = draft.estimated1RmKg == 0
        ? '—'
        : draft.estimated1RmKg.toStringAsFixed(1);
    final volume = draft.totalVolumeKg == 0
        ? '—'
        : draft.totalVolumeKg.toStringAsFixed(0);

    return Row(
      children: [
        Expanded(
          child: _MetricTile(label: 'Est. 1RM', value: e1rm),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricTile(label: 'Total Volume (kg)', value: volume),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
