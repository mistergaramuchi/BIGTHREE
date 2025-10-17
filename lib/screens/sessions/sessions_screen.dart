import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session/demo_data.dart';
import '../../domain/session/models.dart';
import '../../domain/session/session_template.dart';
import '../../domain/session/session_templates_provider.dart';
import '../log/log_screen.dart';

class SessionsScreen extends ConsumerWidget {
  static const routeName = '/sessions';

  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Training Sessions')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  if (sessions.isEmpty) {
                    return const _EmptySessionsPlaceholder();
                  }
                  final template = sessions[index];
                  return _SessionTile(template: template);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: sessions.isEmpty ? 1 : sessions.length,
              ),
            ),
            const SizedBox(height: 16),
            _CreateSessionTile(
              onCreate: () => _showCreateSessionDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateSessionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String selectedMainLiftId = demoMainLifts.first.id;
    final supportOptions = demoSupportExercises;
    final selectedSupportIds = <String>{};

    final template = await showDialog<SessionTemplate>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Session'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Session name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Main lift',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      ...demoMainLifts.map(
                        (exercise) => RadioListTile<String>(
                          title: Text(exercise.name),
                          value: exercise.id,
                          groupValue: selectedMainLiftId,
                          onChanged: (value) {
                            setState(() {
                              selectedMainLiftId = value ?? exercise.id;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Support exercises (optional)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (supportOptions.isEmpty)
                        const Text('Support catalog coming soon.'),
                      if (supportOptions.isNotEmpty)
                        ...supportOptions.map(
                          (exercise) => CheckboxListTile(
                            value: selectedSupportIds.contains(exercise.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked ?? false) {
                                  selectedSupportIds.add(exercise.id);
                                } else {
                                  selectedSupportIds.remove(exercise.id);
                                }
                              });
                            },
                            title: Text(exercise.name),
                            subtitle: Text(exercise.category),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      if (supportOptions.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              selectedSupportIds.isEmpty
                                  ? 'No support work selected.'
                                  : '${selectedSupportIds.length} support exercise(s) selected.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                    final name = nameController.text.trim();
                    final mainLift = demoMainLifts.firstWhere(
                      (exercise) => exercise.id == selectedMainLiftId,
                    );
                    final supports = supportOptions
                        .where(
                          (exercise) =>
                              selectedSupportIds.contains(exercise.id),
                        )
                        .toList();
                    Navigator.of(context).pop(
                      SessionTemplate(
                        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        mainExercise: mainLift,
                        supportExercises: supports,
                      ),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
    });

    if (template != null) {
      ref.read(sessionTemplatesProvider.notifier).addSession(template);
    }
  }
}

class _EmptySessionsPlaceholder extends StatelessWidget {
  const _EmptySessionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No training sessions yet.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first session to start logging your lifter’s work.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.template});

  final SessionTemplate template;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      'Main Lift: ${template.mainExercise.name}',
      if (template.supportExercises.isNotEmpty)
        '${template.supportExercises.length} support exercise${template.supportExercises.length == 1 ? '' : 's'}',
    ];

    return Card(
      child: ExpansionTile(
        title: Text(
          template.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(subtitleParts.join(' · ')),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          _ExerciseListTile(
            label: 'Main Lift',
            exercise: template.mainExercise,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Support Work',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          if (template.supportExercises.isEmpty)
            const Text('No support exercises yet.'),
          if (template.supportExercises.isNotEmpty)
            ...template.supportExercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _ExerciseListTile(
                  label: exercise.category,
                  exercise: exercise,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => _startSession(context),
              child: const Text('Start Session'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _startSession(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LogScreen(template: template)));
  }
}

class _ExerciseListTile extends StatelessWidget {
  const _ExerciseListTile({required this.label, required this.exercise});

  final String label;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(exercise.name),
      subtitle: Text(label),
    );
  }
}

class _CreateSessionTile extends StatelessWidget {
  const _CreateSessionTile({required this.onCreate, super.key});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Need something new?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create New Session'),
            ),
          ],
        ),
      ),
    );
  }
}
