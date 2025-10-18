import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session/session_template.dart';
import '../../domain/session/session_templates_provider.dart';
import 'session_overview_screen.dart';

class SessionsScreen extends ConsumerWidget {
  static const routeName = '/sessions';

  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(sessionTemplatesProvider);
    final orderedChoices = _sessionChoices
        .map(
          (descriptor) => (
            descriptor,
            templates.firstWhere(
              (template) => template.id == descriptor.id,
              orElse: () => descriptor.fallback,
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Session')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemBuilder: (context, index) {
          final (descriptor, template) = orderedChoices[index];
          return _SessionChoiceCard(descriptor: descriptor, template: template);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: orderedChoices.length,
      ),
    );
  }
}

class _SessionChoiceCard extends StatelessWidget {
  const _SessionChoiceCard({required this.descriptor, required this.template});

  final _SessionDescriptor descriptor;
  final SessionTemplate template;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Text(descriptor.code),
        ),
        title: Text(descriptor.title),
        subtitle: Text(descriptor.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionOverviewScreen(
                baseTemplate: template,
                title: descriptor.title,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionDescriptor {
  const _SessionDescriptor({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.fallback,
  });

  final String id;
  final String code;
  final String title;
  final String subtitle;
  final SessionTemplate fallback;
}

const _sessionChoices = [
  _SessionDescriptor(
    id: 'session_squat',
    code: 'S',
    title: 'Squat Session',
    subtitle: 'Lower-body focus built around the squat.',
    fallback: SessionTemplate(
      id: 'session_squat_fallback',
      name: 'Squat Session',
      mainExercise: SessionOverviewScreen.defaultSquatExercise,
    ),
  ),
  _SessionDescriptor(
    id: 'session_bench',
    code: 'B',
    title: 'Bench Session',
    subtitle: 'Pressing emphasis with accessory support.',
    fallback: SessionTemplate(
      id: 'session_bench_fallback',
      name: 'Bench Session',
      mainExercise: SessionOverviewScreen.defaultBenchExercise,
    ),
  ),
  _SessionDescriptor(
    id: 'session_deadlift',
    code: 'D',
    title: 'Deadlift Session',
    subtitle: 'Posterior chain and pull variations.',
    fallback: SessionTemplate(
      id: 'session_deadlift_fallback',
      name: 'Dead Session',
      mainExercise: SessionOverviewScreen.defaultDeadliftExercise,
    ),
  ),
  _SessionDescriptor(
    id: 'session_other',
    code: 'O',
    title: 'Other Session',
    subtitle: 'Accessory or custom session builder.',
    fallback: SessionTemplate(
      id: 'session_other_fallback',
      name: 'Accessory Session',
      mainExercise: SessionOverviewScreen.defaultAccessoryExercise,
    ),
  ),
];
