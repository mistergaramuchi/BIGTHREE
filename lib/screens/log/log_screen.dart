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
    final mainLift = draft.mainLift;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.template.name),
            if (mainLift != null)
              Text(
                'Logging ${mainLift.name}',
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
                    _MainExerciseCard(
                      draft: draft,
                      onSelectLift: () => _showMainLiftSelector(context),
                      onEditWeight: _editMainSetWeight,
                      onAdjustReps: _adjustMainReps,
                      onEditReps: _editMainSetReps,
                    ),
                    const SizedBox(height: 16),
                    if (draft.supports.isEmpty)
                      const _NoSupportExercisesCard()
                    else
                      for (var i = 0; i < draft.supports.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        _SupportExerciseCard(
                          entry: draft.supports[i],
                          onEditWeight: (index) => _editSupportSetWeight(
                            draft.supports[i].exercise.id,
                            index,
                          ),
                          onAdjustReps: (index, delta) => _adjustSupportReps(
                            draft.supports[i].exercise.id,
                            index,
                            delta,
                          ),
                          onEditReps: (index) => _editSupportSetReps(
                            draft.supports[i].exercise.id,
                            index,
                          ),
                          onChangeExercise: () => _changeSupportExercise(
                            draft.supports[i].exercise.id,
                          ),
                        ),
                      ],
                    const SizedBox(height: 16),
                    _SessionMetricsRow(draft: draft),
                  ],
                ),
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
        return SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text('Select main lift'),
                subtitle: Text('Pick a lift to anchor this session.'),
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
          ),
        );
      },
    );

    if (selected != null) {
      notifier.setMainLift(selected);
    }
  }

  Future<void> _changeSupportExercise(String exerciseId) async {
    final notifier = ref.read(sessionDraftProvider.notifier);
    final draft = ref.read(sessionDraftProvider);
    final entry = draft.supports.firstWhere(
      (element) => element.exercise.id == exerciseId,
    );
    final existingIds = {
      for (final support in draft.supports) support.exercise.id,
    }..remove(exerciseId);

    final options = demoExerciseCatalog
        .where(
          (exercise) =>
              exercise.id == exerciseId || !existingIds.contains(exercise.id),
        )
        .toList();

    if (options.isEmpty) return;

    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            itemBuilder: (context, index) {
              final candidate = options[index];
              return ListTile(
                title: Text(candidate.name),
                subtitle: Text(candidate.category),
                onTap: () => Navigator.of(context).pop(candidate),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: options.length,
          ),
        );
      },
    );

    if (selected == null || selected.id == entry.exercise.id) return;
    notifier.replaceSupportExercise(exerciseId, selected);
  }

  Future<void> _editMainSetWeight(int index) async {
    final draft = ref.read(sessionDraftProvider);
    if (index < 0 || index >= draft.mainLiftSets.length) return;
    final set = draft.mainLiftSets[index];
    final newWeight = await _promptWeightDialog(set.weightKg);
    if (newWeight == null) return;
    ref
        .read(sessionDraftProvider.notifier)
        .updateMainLiftSet(index, set.copyWith(weightKg: newWeight));
  }

  Future<void> _editMainSetReps(int index) async {
    final draft = ref.read(sessionDraftProvider);
    if (index < 0 || index >= draft.mainLiftSets.length) return;
    final set = draft.mainLiftSets[index];
    final newReps = await _promptRepsDialog(set.reps);
    if (newReps == null) return;
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateMainLiftSet(index, set.copyWith(reps: newReps));
    notifier.updateMainLiftDefaultReps(newReps);
  }

  Future<void> _editSupportSetWeight(String exerciseId, int index) async {
    final draft = ref.read(sessionDraftProvider);
    final entry = draft.supports.firstWhere(
      (element) => element.exercise.id == exerciseId,
    );
    if (index < 0 || index >= entry.sets.length) return;
    final set = entry.sets[index];
    final newWeight = await _promptWeightDialog(set.weightKg);
    if (newWeight == null) return;
    ref
        .read(sessionDraftProvider.notifier)
        .updateSupportSet(exerciseId, index, set.copyWith(weightKg: newWeight));
  }

  void _adjustMainReps(int index, int delta) {
    final draft = ref.read(sessionDraftProvider);
    if (index < 0 || index >= draft.mainLiftSets.length) return;
    final current = draft.mainLiftSets[index];
    final newReps = (current.reps + delta).clamp(1, 1000);
    if (newReps == current.reps) return;
    final updated = current.copyWith(reps: newReps);
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateMainLiftSet(index, updated);
    notifier.updateMainLiftDefaultReps(newReps);
  }

  void _adjustSupportReps(String exerciseId, int index, int delta) {
    final draft = ref.read(sessionDraftProvider);
    final entry = draft.supports.firstWhere(
      (element) => element.exercise.id == exerciseId,
    );
    if (index < 0 || index >= entry.sets.length) return;
    final current = entry.sets[index];
    final newReps = (current.reps + delta).clamp(1, 1000);
    if (newReps == current.reps) return;
    final updated = current.copyWith(reps: newReps);
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateSupportSet(exerciseId, index, updated);
    notifier.updateSupportDefaultReps(exerciseId, newReps);
  }

  Future<void> _editSupportSetReps(String exerciseId, int index) async {
    final draft = ref.read(sessionDraftProvider);
    final entry = draft.supports.firstWhere(
      (element) => element.exercise.id == exerciseId,
    );
    if (index < 0 || index >= entry.sets.length) return;
    final set = entry.sets[index];
    final newReps = await _promptRepsDialog(set.reps);
    if (newReps == null) return;
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateSupportSet(exerciseId, index, set.copyWith(reps: newReps));
    notifier.updateSupportDefaultReps(exerciseId, newReps);
  }

  Future<int?> _promptRepsDialog(int initialReps) async {
    final formKey = GlobalKey<FormState>();
    final repsController = TextEditingController(text: initialReps.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Reps'),
          content: Form(
            key: formKey,
            child: TextFormField(
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop(int.parse(repsController.text));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    repsController.dispose();
    return result;
  }

  Future<double?> _promptWeightDialog(double initialWeight) async {
    final controller = TextEditingController(
      text: initialWeight == 0 ? '' : _formatWeight(initialWeight),
    );

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Weight',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final parsed = double.tryParse(controller.text);
                      if (parsed == null || parsed <= 0) return;
                      Navigator.of(context).pop(parsed);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
    return result;
  }
}

class _MainExerciseCard extends StatelessWidget {
  const _MainExerciseCard({
    required this.draft,
    required this.onSelectLift,
    required this.onEditWeight,
    required this.onAdjustReps,
    required this.onEditReps,
  });

  final SessionDraft draft;
  final VoidCallback onSelectLift;
  final void Function(int) onEditWeight;
  final void Function(int, int) onAdjustReps;
  final void Function(int) onEditReps;

  @override
  Widget build(BuildContext context) {
    final exercise = draft.mainLift;

    if (exercise == null) {
      return Card(
        child: ListTile(
          leading: const _ExerciseAvatar(icon: Icons.add),
          title: const Text('Select main lift'),
          subtitle: const Text('Pick a main exercise to start logging sets.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onSelectLift,
        ),
      );
    }

    final sets = draft.mainLiftSets;
    return Card(
      child: ExpansionTile(
        leading: _ExerciseAvatar(label: exercise.name),
        title: Text(exercise.name),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                sets.isEmpty
                    ? 'No sets logged yet'
                    : '${sets.length} set${sets.length == 1 ? '' : 's'} logged',
              ),
            ),
            IconButton(
              tooltip: 'Change exercise',
              icon: const Icon(Icons.swap_horiz),
              onPressed: onSelectLift,
            ),
          ],
        ),
        maintainState: true,
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          if (sets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('No sets logged yet.'),
            ),
          if (sets.isNotEmpty)
            for (var i = 0; i < sets.length; i++)
              _SetRow(
                index: i,
                set: sets[i],
                onEditWeight: () => onEditWeight(i),
                onTapReps: () => onEditReps(i),
                onAdjustReps: (delta) => onAdjustReps(i, delta),
              ),
        ],
      ),
    );
  }
}

class _SupportExerciseCard extends StatelessWidget {
  const _SupportExerciseCard({
    required this.entry,
    required this.onEditWeight,
    required this.onAdjustReps,
    required this.onEditReps,
    required this.onChangeExercise,
  });

  final SupportExerciseEntry entry;
  final void Function(int) onEditWeight;
  final void Function(int, int) onAdjustReps;
  final void Function(int) onEditReps;
  final VoidCallback onChangeExercise;

  @override
  Widget build(BuildContext context) {
    final sets = entry.sets;
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        leading: _ExerciseAvatar(label: entry.exercise.name),
        title: Text(entry.exercise.name),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                sets.isEmpty
                    ? 'No sets logged yet'
                    : '${sets.length} set${sets.length == 1 ? '' : 's'} logged',
              ),
            ),
            IconButton(
              tooltip: 'Change exercise',
              icon: const Icon(Icons.swap_horiz),
              onPressed: onChangeExercise,
            ),
          ],
        ),
        maintainState: true,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          if (sets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tap the swap icon to pick a different exercise or start logging.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (sets.isNotEmpty)
            for (var i = 0; i < sets.length; i++)
              _SetRow(
                index: i,
                set: sets[i],
                onEditWeight: () => onEditWeight(i),
                onTapReps: () => onEditReps(i),
                onAdjustReps: (delta) => onAdjustReps(i, delta),
              ),
        ],
      ),
    );
  }
}

class _NoSupportExercisesCard extends StatelessWidget {
  const _NoSupportExercisesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No additional exercises were selected in the overview.',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.onEditWeight,
    required this.onTapReps,
    required this.onAdjustReps,
  });

  final int index;
  final LiftSet set;
  final VoidCallback onEditWeight;
  final VoidCallback onTapReps;
  final void Function(int delta) onAdjustReps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text('${index + 1}', style: theme.textTheme.titleSmall),
              const SizedBox(width: 16),
              _ValueChip(
                label: 'kg',
                value: _formatWeight(set.weightKg),
                onTap: onEditWeight,
              ),
              const SizedBox(width: 16),
              _ValueChip(
                label: 'reps',
                value: set.reps.toString(),
                onTap: onTapReps,
              ),
              const Spacer(),
              _RepsCounter(
                reps: set.reps,
                onDecrement: () => onAdjustReps(-1),
                onIncrement: () => onAdjustReps(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepsCounter extends StatelessWidget {
  const _RepsCounter({
    required this.reps,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int reps;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 20,
            onPressed: reps > 1 ? onDecrement : null,
            splashRadius: 20,
            icon: const Icon(Icons.remove),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              reps.toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            iconSize: 20,
            onPressed: onIncrement,
            splashRadius: 20,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceVariant,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: theme.textTheme.titleMedium),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ExerciseAvatar extends StatelessWidget {
  const _ExerciseAvatar({this.label, this.icon = Icons.fitness_center});

  final String? label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.primaryContainer;
    final foreground = theme.colorScheme.onPrimaryContainer;

    if (label == null || label!.isEmpty) {
      return CircleAvatar(
        backgroundColor: background,
        foregroundColor: foreground,
        child: Icon(icon),
      );
    }

    return CircleAvatar(
      backgroundColor: background,
      foregroundColor: foreground,
      child: Text(label![0].toUpperCase()),
    );
  }
}

String _formatWeight(double weight) {
  return weight % 1 == 0
      ? weight.toStringAsFixed(0)
      : weight.toStringAsFixed(1);
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
