import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session/demo_data.dart';
import '../../domain/session/exercise_catalog_loader.dart';
import '../../domain/session/models.dart';
import '../../domain/session/session_templates_provider.dart';
import '../../ui/responsive/layout_constants.dart';
import '../log/log_screen.dart';

class SessionOverviewScreen extends ConsumerStatefulWidget {
  const SessionOverviewScreen({
    required this.baseTemplate,
    this.subtitle = 'Review and customize before you start',
    this.canDeleteTemplate = false,
    super.key,
  });

  final SessionTemplate baseTemplate;
  final String subtitle;
  final bool canDeleteTemplate;

  static const Exercise defaultSquatExercise = squatLowBar;
  static const Exercise defaultBenchExercise = benchCompetition;
  static const Exercise defaultDeadliftExercise = deadliftConventional;
  static const Exercise defaultAccessoryExercise = barbellRow;

  @override
  ConsumerState<SessionOverviewScreen> createState() =>
      _SessionOverviewScreenState();
}

class _SessionOverviewScreenState extends ConsumerState<SessionOverviewScreen> {
  late SessionTemplate _template;
  late List<Exercise> _selectedExercises;
  late String _sessionName;

  bool get _hasExercises => _selectedExercises.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _template = widget.baseTemplate;
    _sessionName = _template.name;
    var combined = List<Exercise>.from(_template.exercises);
    if (combined.isEmpty) {
      combined = [SessionOverviewScreen.defaultAccessoryExercise];
    }
    _selectedExercises = _uniquifyExercises(combined);
  }

  Future<List<Exercise>> _getExerciseCatalog() async {
    return ExerciseCatalogLoader.instance.load();
  }

  void _showCatalogLoadError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to load exercise catalog. Confirm assets/data/exercises.json is bundled.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sessionName.isEmpty ? 'Session' : _sessionName),
            Text(
              widget.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Edit name',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _promptRename,
          ),
        ],
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
                    'Changes are saved automatically to this session template.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _hasExercises ? _startSession : null,
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
    _persistTemplate();
  }

  Future<void> _changeExercise(int index) async {
    final current = _selectedExercises[index];
    final existingIds = _selectedExercises
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value.id)
        .toSet();

    List<Exercise> catalog;
    try {
      catalog = await _getExerciseCatalog();
    } catch (error, stackTrace) {
      debugPrint(
        'SessionOverviewScreen: failed to load exercise catalog. $error\n$stackTrace',
      );
      _showCatalogLoadError();
      return;
    }
    final options = catalog.where((exercise) {
      final isCurrent = exercise.id == current.id;
      if (!isCurrent && existingIds.contains(exercise.id)) return false;
      return true;
    }).toList();

    if (options.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No alternative exercises available.')),
      );
      return;
    }

    final selected = await _showExercisePicker(
      candidates: options,
      title: 'Swap Exercise',
    );

    if (selected == null || selected.id == current.id) return;

    setState(() {
      _selectedExercises[index] = selected;
    });
    _persistTemplate();
  }

  Future<void> _showAddExerciseSheet() async {
    List<Exercise> catalog;
    try {
      catalog = await _getExerciseCatalog();
    } catch (error, stackTrace) {
      debugPrint(
        'SessionOverviewScreen: failed to load exercise catalog. $error\n$stackTrace',
      );
      _showCatalogLoadError();
      return;
    }
    final selectedIds = _selectedExercises
        .map((exercise) => exercise.id)
        .toSet();
    final available = catalog
        .where((exercise) => !selectedIds.contains(exercise.id))
        .toList();

    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All catalog exercises already added.')),
      );
      return;
    }

    final exercise = await _showExercisePicker(
      candidates: available,
      title: 'Choose an Exercise',
    );

    if (exercise == null) return;

    setState(() {
      _selectedExercises = _uniquifyExercises([
        ..._selectedExercises,
        exercise,
      ]);
    });
    _persistTemplate();
  }

  void _startSession() {
    final template = _template.copyWith(
      name: _sessionName,
      exercises: List<Exercise>.from(_selectedExercises),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LogScreen(template: template)),
    );
  }

  void _persistTemplate() {
    final hasExercises = _selectedExercises.isNotEmpty;
    final status = hasExercises
        ? (_template.status == SessionStatus.draft
            ? SessionStatus.active
            : _template.status)
        : SessionStatus.draft;
    _template = _template.copyWith(
      name: _sessionName,
      status: status,
      exercises: List<Exercise>.from(_selectedExercises),
      updatedAt: DateTime.now(),
    );
    ref.read(sessionTemplatesProvider.notifier).addSession(_template);
  }

  void _promptRename() {
    final controller = TextEditingController(text: _sessionName);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Session'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Enter session name'),
          ),
          actions: [
            if (widget.canDeleteTemplate)
              TextButton(
                onPressed: () {
                  ref
                      .read(sessionTemplatesProvider.notifier)
                      .removeSession(_template.id);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    _sessionName = value;
                  }
                });
                Navigator.of(context).pop();
                _persistTemplate();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
