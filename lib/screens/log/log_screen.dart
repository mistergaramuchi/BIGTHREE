import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session/exercise_catalog_loader.dart';
import '../../domain/session/models.dart';
import '../../domain/session/session_draft_notifier.dart';
import '../../ui/responsive/layout_constants.dart';
import '../summary/summary_screen.dart';
import 'widgets/dismissible_set_row.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key, required this.template});

  final SessionTemplate template;

  static const routeName = '/log';

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  int? _expandedExerciseIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(sessionDraftProvider.notifier);
      notifier.loadFromTemplate(widget.template);
      final exercises = ref.read(sessionDraftProvider).exercises;
      if (exercises.isNotEmpty) {
        setState(() {
          _expandedExerciseIndex = 0;
        });
      }
    });
  }

  void _viewSummary(BuildContext context) {
    Navigator.of(context).pushNamed(SummaryScreen.routeName);
  }

  void _handleExpansion(int index, bool expanded) {
    setState(() {
      _expandedExerciseIndex = expanded ? index : null;
    });
  }

  Future<void> _changeExercise(SessionExerciseEntry entry) async {
    final draft = ref.read(sessionDraftProvider);
    final existingIds = {
      for (final exercise in draft.exercises) exercise.exercise.id,
    }..remove(entry.exercise.id);

    List<Exercise> catalog;
    try {
      catalog = await _loadCatalog();
    } catch (error, stackTrace) {
      debugPrint(
        'LogScreen: failed to load exercise catalog. $error\n$stackTrace',
      );
      _showSnackBar(
        'Unable to load exercise catalog. Confirm assets/data/exercises.json is bundled.',
      );
      return;
    }
    final options = catalog.where((candidate) {
      final isCurrent = candidate.id == entry.exercise.id;
      if (!isCurrent && existingIds.contains(candidate.id)) return false;
      return true;
    }).toList();

    if (options.isEmpty) {
      _showSnackBar('No alternative exercises available.');
      return;
    }

    final selection = await _showExercisePicker(
      candidates: options,
      title: 'Swap Exercise',
    );

    if (selection == null || selection.id == entry.exercise.id) return;
    ref
        .read(sessionDraftProvider.notifier)
        .replaceExercise(entry.exercise.id, selection);
  }

  void _updateExerciseSetWeight(
    String exerciseId,
    int setIndex,
    double weight,
  ) {
    final draft = ref.read(sessionDraftProvider);
    final entry = draft.exerciseById(exerciseId);
    if (entry == null || setIndex < 0 || setIndex >= entry.sets.length) {
      return;
    }
    final set = entry.sets[setIndex].copyWith(weightKg: weight);
    ref
        .read(sessionDraftProvider.notifier)
        .updateExerciseSet(exerciseId, setIndex, set);
  }

  void _updateExerciseSetReps(String exerciseId, int setIndex, int reps) {
    final draft = ref.read(sessionDraftProvider);
    final entry = draft.exerciseById(exerciseId);
    if (entry == null || setIndex < 0 || setIndex >= entry.sets.length) {
      return;
    }
    final set = entry.sets[setIndex].copyWith(reps: reps);
    final notifier = ref.read(sessionDraftProvider.notifier);
    notifier.updateExerciseSet(exerciseId, setIndex, set);
    notifier.updateExerciseDefaultReps(exerciseId, reps);
  }

  void _addSet(SessionExerciseEntry entry) {
    ref.read(sessionDraftProvider.notifier).addExerciseSet(entry.exercise.id);
    setState(() {
      final draft = ref.read(sessionDraftProvider);
      _expandedExerciseIndex = draft.exercises.indexWhere(
        (e) => e.exercise.id == entry.exercise.id,
      );
    });
  }

  void _removeSet(String exerciseId, int setIndex) {
    ref
        .read(sessionDraftProvider.notifier)
        .removeExerciseSet(exerciseId, setIndex);
    setState(() {});
  }

  void _logCurrentSet() {
    final draft = ref.read(sessionDraftProvider);
    if (draft.exercises.isEmpty) {
      _showSnackBar('No exercises available to log.');
      return;
    }
    final index = _expandedExerciseIndex == null
        ? 0
        : _expandedExerciseIndex!.clamp(0, draft.exercises.length - 1);
    final entry = draft.exercises[index];
    final pendingIndex = entry.currentSetIndex;
    final notifier = ref.read(sessionDraftProvider.notifier);
    final result = notifier.logNextSet(entry.exercise.id);

    switch (result) {
      case LogSetResult.success:
        FocusScope.of(context).unfocus();
        final setNumber = (pendingIndex ?? 0) + 1;
        _showSnackBar('Set $setNumber logged for ${entry.exercise.name}.');
        break;
      case LogSetResult.noPendingSets:
        _showSnackBar(
          'All sets for ${entry.exercise.name} are already logged.',
        );
        break;
      case LogSetResult.invalidValues:
        _showSnackBar('Enter kg and reps before logging this set.');
        break;
      case LogSetResult.missingExercise:
        _showSnackBar('Exercise no longer available.');
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<List<Exercise>> _loadCatalog() async {
    return ExerciseCatalogLoader.instance.load();
  }

  Future<Exercise?> _showExercisePicker({
    required List<Exercise> candidates,
    String title = 'Choose an Exercise',
  }) async {
    if (candidates.isEmpty) return null;

    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        var filter = '';
        final expandedCategories = <String>{};

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final query = filter.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? candidates
                    : candidates.where((exercise) {
                        final haystack = StringBuffer()
                          ..write(exercise.name.toLowerCase())
                          ..write(' ')
                          ..write(exercise.category.toLowerCase())
                          ..write(' ')
                          ..write(exercise.modality.toLowerCase())
                          ..write(' ')
                          ..write(exercise.tags.join(' ').toLowerCase());
                        return haystack.toString().contains(query);
                      }).toList();

                final categoryMap = <String, List<Exercise>>{};
                for (final item in filtered) {
                  final key = item.category.isEmpty ? 'Other' : item.category;
                  categoryMap.putIfAbsent(key, () => []).add(item);
                }
                final categories = categoryMap.keys.toList()..sort();
                for (final key in categories) {
                  categoryMap[key]!.sort((a, b) => a.name.compareTo(b.name));
                  expandedCategories.add(key);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          height: 4,
                          width: 48,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search exercises…',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    setModalState(() => filter = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: categories.isEmpty
                              ? Center(
                                  child: Text(
                                    query.isEmpty
                                        ? 'No exercises available.'
                                        : 'No exercises found for "${filter.trim()}".',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                )
                              : ListView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.only(bottom: 24),
                                  children: [
                                    for (final category in categories)
                                      ExpansionTile(
                                        title: Text(
                                          category,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                        tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        initiallyExpanded: expandedCategories
                                            .contains(category),
                                        onExpansionChanged: (expanded) {
                                          setModalState(() {
                                            if (expanded) {
                                              expandedCategories.add(category);
                                            } else {
                                              expandedCategories.remove(
                                                category,
                                              );
                                            }
                                          });
                                        },
                                        children: [
                                          for (final item
                                              in categoryMap[category]!)
                                            ListTile(
                                              title: Text(item.name),
                                              subtitle: item.modality.isEmpty
                                                  ? null
                                                  : Text(item.modality),
                                              onTap: () => Navigator.of(
                                                context,
                                              ).pop(item),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(sessionDraftProvider);
    final exercises = draft.exercises;
    final padding = LayoutConstants.responsivePadding(context);
    final gap = LayoutConstants.responsiveGap(context) / 2;
    final primaryExercise = draft.primaryExercise?.exercise;
    final expandedIndex = _expandedExerciseIndex;

    if (exercises.isNotEmpty &&
        (expandedIndex == null || expandedIndex >= exercises.length)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _expandedExerciseIndex = 0;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.template.name),
            if (primaryExercise != null)
              Text(
                'Logging ${primaryExercise.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: exercises.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _logCurrentSet,
              icon: const Icon(Icons.check),
              label: const Text('Log Set'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            padding.bottom + (exercises.isEmpty ? 0 : 80),
          ),
          child: LayoutConstants.maxWidthConstrained(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (exercises.isEmpty)
                        const _EmptyExercisesMessage()
                      else
                        for (var i = 0; i < exercises.length; i++) ...[
                          if (i > 0) SizedBox(height: gap),
                          _SessionExerciseCard(
                            entry: exercises[i],
                            isExpanded: _expandedExerciseIndex == i,
                            onToggle: (expanded) =>
                                _handleExpansion(i, expanded),
                            onWeightChanged: (setIndex, weight) =>
                                _updateExerciseSetWeight(
                                  exercises[i].exercise.id,
                                  setIndex,
                                  weight,
                                ),
                            onRepsChanged: (setIndex, reps) =>
                                _updateExerciseSetReps(
                                  exercises[i].exercise.id,
                                  setIndex,
                                  reps,
                                ),
                            onChangeExercise: () =>
                                _changeExercise(exercises[i]),
                            onAddSet: () => _addSet(exercises[i]),
                            onRemoveSet: (setIndex) =>
                                _removeSet(exercises[i].exercise.id, setIndex),
                          ),
                        ],
                      SizedBox(height: gap),
                      _SessionMetricsRow(draft: draft),
                    ],
                  ),
                ),
                SizedBox(height: gap),
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
}

class _SessionExerciseCard extends StatelessWidget {
  const _SessionExerciseCard({
    required this.entry,
    required this.isExpanded,
    required this.onToggle,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onChangeExercise,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  final SessionExerciseEntry entry;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;
  final void Function(int setIndex, double weight) onWeightChanged;
  final void Function(int setIndex, int reps) onRepsChanged;
  final VoidCallback onChangeExercise;
  final VoidCallback onAddSet;
  final void Function(int setIndex) onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final sets = entry.sets;
    final loggedCount = sets.where((set) => set.isLogged).length;
    final subtitle = sets.isEmpty
        ? 'No sets configured'
        : '$loggedCount of ${sets.length} sets logged';

    final tileKey = ValueKey(
      'exercise_${entry.exercise.id}_${isExpanded ? 'open' : 'closed'}',
    );

    return Card(
      child: ExpansionTile(
        key: tileKey,
        initiallyExpanded: isExpanded,
        maintainState: true,
        leading: _ExerciseAvatar(label: entry.exercise.name),
        title: Text(entry.exercise.name),
        subtitle: Row(
          children: [
            Expanded(child: Text(subtitle)),
            IconButton(
              tooltip: 'Change exercise',
              icon: const Icon(Icons.swap_horiz),
              onPressed: onChangeExercise,
            ),
          ],
        ),
        onExpansionChanged: onToggle,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          for (var i = 0; i < sets.length; i++)
            (() {
              final index = i;
              return DismissibleSetRow(
                dismissibleKey: ValueKey('${entry.exercise.id}_set_$index'),
                onRemove: () => onRemoveSet(index),
                child: _SetRow(
                  index: index,
                  set: sets[index],
                  isCurrent: entry.currentSetIndex == index,
                  onWeightChanged: (value) => onWeightChanged(index, value),
                  onRepsChanged: (value) => onRepsChanged(index, value),
                ),
              );
            })(),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add),
                label: const Text('Add another set'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExercisesMessage extends StatelessWidget {
  const _EmptyExercisesMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No exercises were selected for this session.',
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
    required this.isCurrent,
  });

  final int index;
  final LiftSet set;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final bool isCurrent;

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
      text: _formatWeight(widget.set.weightKg),
    );
    _repsController = TextEditingController(text: widget.set.reps.toString());
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final weightText = _formatWeight(widget.set.weightKg);
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
    if (parsed == null || parsed < 0) {
      _weightController.text = _formatWeight(widget.set.weightKg);
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
    final isLogged = widget.set.isLogged;
    final highlightColor = widget.isCurrent && !isLogged
        ? theme.colorScheme.secondaryContainer
        : isLogged
        ? theme.colorScheme.surfaceVariant.withOpacity(0.6)
        : null;
    final borderColor = widget.isCurrent && !isLogged
        ? theme.colorScheme.secondary
        : isLogged
        ? theme.colorScheme.outline
        : theme.dividerColor;
    final textStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: widget.isCurrent ? FontWeight.w600 : FontWeight.w500,
      color: isLogged ? theme.colorScheme.onSurfaceVariant : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlightColor,
          border: Border.all(color: borderColor),
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
                  Text('${widget.index + 1}', style: textStyle),
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
                  const Spacer(),
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
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onSubmitted;
  final TextInputType keyboardType;
  final double? width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: enabled,
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
