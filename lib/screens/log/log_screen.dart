import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session/demo_data.dart';
import '../../domain/session/models.dart';
import '../../domain/session/session_draft_notifier.dart';
import '../../domain/session/session_template.dart';
import '../../ui/responsive/layout_constants.dart';
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
          padding: LayoutConstants.responsivePadding(context),
          child: LayoutConstants.maxWidthConstrained(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _MainExerciseCard(
                        draft: draft,
                        onSelectLift: () => _showMainLiftSelector(context),
                        onWeightChanged: _updateMainSetWeight,
                        onRepsChanged: _updateMainSetReps,
                        onAdjustReps: _adjustMainReps,
                      ),
                      SizedBox(
                        height: LayoutConstants.responsiveGap(context) / 2,
                      ),
                      if (draft.supports.isEmpty)
                        const _NoSupportExercisesCard()
                      else
                        for (var i = 0; i < draft.supports.length; i++) ...[
                          if (i > 0)
                            SizedBox(
                              height:
                                  LayoutConstants.responsiveGap(context) / 2,
                            ),
                          _SupportExerciseCard(
                            entry: draft.supports[i],
                            onWeightChanged: (index, weight) =>
                                _updateSupportSetWeight(
                                  draft.supports[i].exercise.id,
                                  index,
                                  weight,
                                ),
                            onRepsChanged: (index, reps) =>
                                _updateSupportSetReps(
                                  draft.supports[i].exercise.id,
                                  index,
                                  reps,
                                ),
                            onAdjustReps: (index, delta) => _adjustSupportReps(
                              draft.supports[i].exercise.id,
                              index,
                              delta,
                            ),
                            onChangeExercise: () => _changeSupportExercise(
                              draft.supports[i].exercise.id,
                            ),
                          ),
                        ],
                      SizedBox(
                        height: LayoutConstants.responsiveGap(context) / 2,
                      ),
                      _SessionMetricsRow(draft: draft),
                    ],
                  ),
                ),
                SizedBox(height: LayoutConstants.responsiveGap(context) / 2),
                FilledButton(
                  onPressed: () => _viewSummary(context),
                  child: const Text('Review Summary'),
                ),
              ],
            ),
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

  void _updateMainSetWeight(int index, double weight) {
    final draft = ref.read(sessionDraftProvider);
    if (index < 0 || index >= draft.mainLiftSets.length) return;
    final set = draft.mainLiftSets[index].copyWith(weightKg: weight);
    ref.read(sessionDraftProvider.notifier).updateMainLiftSet(index, set);
  }

  void _updateMainSetReps(int index, int reps) {
    final draft = ref.read(sessionDraftProvider);
    if (index < 0 || index >= draft.mainLiftSets.length) return;
    final set = draft.mainLiftSets[index].copyWith(reps: reps);
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateMainLiftSet(index, set);
    notifier.updateMainLiftDefaultReps(reps);
  }

  void _updateSupportSetWeight(String exerciseId, int index, double weight) {
    final draft = ref.read(sessionDraftProvider);
    final entry = draft.supports.firstWhere(
      (element) => element.exercise.id == exerciseId,
    );
    if (index < 0 || index >= entry.sets.length) return;
    final set = entry.sets[index].copyWith(weightKg: weight);
    ref
        .read(sessionDraftProvider.notifier)
        .updateSupportSet(exerciseId, index, set);
  }

  void _updateSupportSetReps(String exerciseId, int index, int reps) {
    final draft = ref.read(sessionDraftProvider);
    final entry = draft.supports.firstWhere(
      (element) => element.exercise.id == exerciseId,
    );
    if (index < 0 || index >= entry.sets.length) return;
    final set = entry.sets[index].copyWith(reps: reps);
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateSupportSet(exerciseId, index, set);
    notifier.updateSupportDefaultReps(exerciseId, reps);
  }

  void _adjustMainReps(int index, int delta) {
    final draft = ref.read(sessionDraftProvider);
    if (index < 0 || index >= draft.mainLiftSets.length) return;
    final current = draft.mainLiftSets[index];
    final newReps = (current.reps + delta).clamp(1, 1000);
    if (newReps == current.reps) return;
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateMainLiftSet(index, current.copyWith(reps: newReps));
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
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateSupportSet(
      exerciseId,
      index,
      current.copyWith(reps: newReps),
    );
    notifier.updateSupportDefaultReps(exerciseId, newReps);
  }
}

class _MainExerciseCard extends StatelessWidget {
  const _MainExerciseCard({
    required this.draft,
    required this.onSelectLift,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onAdjustReps,
  });

  final SessionDraft draft;
  final VoidCallback onSelectLift;
  final void Function(int index, double weight) onWeightChanged;
  final void Function(int index, int reps) onRepsChanged;
  final void Function(int index, int delta) onAdjustReps;

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
        subtitle: Text(
          sets.isEmpty
              ? 'No sets logged yet'
              : '${sets.length} set${sets.length == 1 ? '' : 's'} logged',
        ),
        maintainState: true,
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          for (var i = 0; i < sets.length; i++)
            _SetRow(
              index: i,
              set: sets[i],
              onWeightChanged: (value) => onWeightChanged(i, value),
              onRepsChanged: (value) => onRepsChanged(i, value),
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
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onAdjustReps,
    required this.onChangeExercise,
  });

  final SupportExerciseEntry entry;
  final void Function(int index, double weight) onWeightChanged;
  final void Function(int index, int reps) onRepsChanged;
  final void Function(int index, int delta) onAdjustReps;
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
                'Sets will appear here once logging begins.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (var i = 0; i < sets.length; i++)
            _SetRow(
              index: i,
              set: sets[i],
              onWeightChanged: (value) => onWeightChanged(i, value),
              onRepsChanged: (value) => onRepsChanged(i, value),
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

class _SetRow extends StatefulWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onAdjustReps,
  });

  final int index;
  final LiftSet set;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final void Function(int delta) onAdjustReps;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weightKg == 0 ? '' : _formatWeight(widget.set.weightKg),
    );
    _repsController = TextEditingController(text: widget.set.reps.toString());
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final weightText = widget.set.weightKg == 0
        ? ''
        : _formatWeight(widget.set.weightKg);
    if (_weightController.text != weightText) {
      _weightController.text = weightText;
    }
    final repsText = widget.set.reps.toString();
    if (_repsController.text != repsText) {
      _repsController.text = repsText;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _handleWeightSubmitted(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      _weightController.text = widget.set.weightKg == 0
          ? ''
          : _formatWeight(widget.set.weightKg);
      return;
    }
    widget.onWeightChanged(parsed);
  }

  void _handleRepsSubmitted(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      _repsController.text = widget.set.reps.toString();
      return;
    }
    widget.onRepsChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isCompact = width < 320;
              final fieldWidth = isCompact ? 54.0 : 72.0;
              final gap = isCompact ? 6.0 : 12.0;

              return Row(
                children: [
                  Text(
                    '${widget.index + 1}',
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(width: gap),
                  _InlineNumberField(
                    controller: _weightController,
                    label: 'kg',
                    onSubmitted: _handleWeightSubmitted,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    width: fieldWidth,
                  ),
                  SizedBox(width: gap),
                  _InlineNumberField(
                    controller: _repsController,
                    label: 'reps',
                    onSubmitted: _handleRepsSubmitted,
                    keyboardType: TextInputType.number,
                    width: fieldWidth,
                  ),
                  SizedBox(width: gap),
                  _RepsCounter(
                    reps: widget.set.reps,
                    onDecrement: () => widget.onAdjustReps(-1),
                    onIncrement: () => widget.onAdjustReps(1),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InlineNumberField extends StatelessWidget {
  const _InlineNumberField({
    required this.controller,
    required this.label,
    required this.onSubmitted,
    required this.keyboardType,
    this.width,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onSubmitted;
  final TextInputType keyboardType;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
        ),
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            iconSize: 20,
            onPressed: reps > 1 ? onDecrement : null,
            splashRadius: 20,
            icon: const Icon(Icons.remove),
          ),
        ),
        const SizedBox(width: 4),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 8),
        //   child: Text(
        //     reps.toString(),
        //     style: Theme.of(context).textTheme.titleMedium,
        //   ),
        // ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            iconSize: 20,
            onPressed: onIncrement,
            splashRadius: 20,
            icon: const Icon(Icons.add),
          ),
        ),
      ],
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
