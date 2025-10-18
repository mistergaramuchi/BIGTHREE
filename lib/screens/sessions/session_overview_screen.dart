import 'package:flutter/material.dart';

import '../../domain/session/demo_data.dart';
import '../../domain/session/models.dart';
import '../../domain/session/session_template.dart';
import '../../ui/responsive/layout_constants.dart';
import '../log/log_screen.dart';

class SessionOverviewScreen extends StatefulWidget {
  const SessionOverviewScreen({
    required this.baseTemplate,
    required this.title,
    super.key,
  });

  final SessionTemplate baseTemplate;
  final String title;

  static const Exercise defaultSquatExercise = squatLowBar;
  static const Exercise defaultBenchExercise = benchCompetition;
  static const Exercise defaultDeadliftExercise = deadliftConventional;
  static const Exercise defaultAccessoryExercise = barbellRow;

  @override
  State<SessionOverviewScreen> createState() => _SessionOverviewScreenState();
}

class _SessionOverviewScreenState extends State<SessionOverviewScreen> {
  late List<Exercise> _selectedExercises;

  @override
  void initState() {
    super.initState();
    final combined = <Exercise>[
      widget.baseTemplate.mainExercise,
      ...widget.baseTemplate.supportExercises,
    ];
    if (combined.isEmpty) {
      combined.add(SessionOverviewScreen.defaultAccessoryExercise);
    }
    _selectedExercises = _uniquifyExercises(combined);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.title} Overview'),
            Text(
              'Review and customize before you start',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: LayoutConstants.responsivePadding(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = LayoutConstants.responsiveGap(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Exercises', style: theme.textTheme.titleLarge),
                SizedBox(height: gap / 2),
                Expanded(
                  child: LayoutConstants.maxWidthConstrained(
                    child: Card(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          if (index == _selectedExercises.length) {
                            return ListTile(
                              leading: const Icon(Icons.add_circle_outline),
                              title: const Text('+ Add an exercise'),
                              onTap: _showAddExerciseSheet,
                            );
                          }
                          final exercise = _selectedExercises[index];
                          final isMain = index == 0;
                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(exercise.name),
                            subtitle: Text(
                              exercise.category.isEmpty
                                  ? 'Exercise'
                                  : exercise.category,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Change exercise',
                                  icon: const Icon(Icons.swap_horiz),
                                  onPressed: () => _changeExercise(index),
                                ),
                                if (!isMain)
                                  IconButton(
                                    tooltip: 'Remove exercise',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _removeExercise(exercise.id),
                                  ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: _selectedExercises.length + 1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: gap / 2),
                LayoutConstants.maxWidthConstrained(
                  child: Text(
                    'Tap “+ Add an exercise” to pull options from the quick catalog.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedExercises.isEmpty ? null : _startSession,
        icon: const Icon(Icons.play_arrow),
        label: const Text('START SESSION'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _removeExercise(String exerciseId) {
    setState(() {
      _selectedExercises.removeWhere((exercise) => exercise.id == exerciseId);
    });
  }

  Future<void> _changeExercise(int index) async {
    final current = _selectedExercises[index];
    final isMain = index == 0;
    final existingIds = _selectedExercises
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value.id)
        .toSet();

    final pool = isMain ? demoMainLifts : demoExerciseCatalog;
    final options = pool.where((exercise) {
      if (exercise.id == current.id) return true;
      return !existingIds.contains(exercise.id);
    }).toList();

    if (options.isEmpty) return;

    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            itemBuilder: (context, i) {
              final candidate = options[i];
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

    if (selected == null || selected.id == current.id) return;

    setState(() {
      final updated = [..._selectedExercises];
      updated[index] = selected;
      _selectedExercises = _uniquifyExercises(updated);
    });
  }

  Future<void> _showAddExerciseSheet() async {
    final selectedIds = _selectedExercises
        .map((exercise) => exercise.id)
        .toSet();
    final available = demoExerciseCatalog
        .where((exercise) => !selectedIds.contains(exercise.id))
        .toList();

    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All catalog exercises already added.')),
      );
      return;
    }

    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            itemBuilder: (context, index) {
              final item = available[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.category),
                onTap: () => Navigator.of(context).pop(item),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: available.length,
          ),
        );
      },
    );

    if (exercise == null) return;

    setState(() {
      _selectedExercises = _uniquifyExercises([
        ..._selectedExercises,
        exercise,
      ]);
    });
  }

  void _startSession() {
    final main = _selectedExercises.first;
    final supports = _selectedExercises.skip(1).toList();
    final template = widget.baseTemplate.copyWith(
      id: '${widget.baseTemplate.id}_${DateTime.now().millisecondsSinceEpoch}',
      mainExercise: main,
      supportExercises: supports,
    );

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LogScreen(template: template)));
  }

  static List<Exercise> _uniquifyExercises(List<Exercise> exercises) {
    final ids = <String>{};
    final unique = <Exercise>[];
    for (final exercise in exercises) {
      if (ids.add(exercise.id)) {
        unique.add(exercise);
      }
    }
    return unique;
  }
}
