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
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemBuilder: (context, index) {
          final template = sessions[index];
          return _SessionCard(template: template);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: sessions.length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSessionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Session'),
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Support exercise selection coming soon.',
                          style: TextStyle(fontSize: 12),
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
                    Navigator.of(context).pop(
                      SessionTemplate(
                        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        mainExercise: mainLift,
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

    nameController.dispose();

    if (template != null) {
      ref.read(sessionTemplatesProvider.notifier).addSession(template);
    }
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.template});

  final SessionTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton(
                  onPressed: () => _startSession(context),
                  child: const Text('Start Session'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ExerciseListTile(
              label: 'Main Lift',
              exercise: template.mainExercise,
            ),
            const SizedBox(height: 12),
            Text('Support Work', style: Theme.of(context).textTheme.titleSmall),
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
          ],
        ),
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
