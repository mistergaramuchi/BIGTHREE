import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session/models.dart';
import '../../domain/session/programs_provider.dart';
import '../../ui/responsive/layout_constants.dart';
import '../sessions/sessions_screen.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  static const routeName = '/programs';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider);
    final sorted = [...programs]
      ..sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return a.name.compareTo(b.name);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Your Programs')),
      body: Padding(
        padding: LayoutConstants.responsivePadding(context),
        child: LayoutConstants.maxWidthConstrained(
          child: ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: LayoutConstants.responsiveGap(context) / 2),
            itemBuilder: (context, index) {
              final program = sorted[index];
              return _ProgramCard(program: program);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProgram(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Create Program'),
      ),
    );
  }

  Future<void> _createProgram(BuildContext context, WidgetRef ref) async {
    final id = 'program_${DateTime.now().millisecondsSinceEpoch}';
    final program = Program(
      id: id,
      name: 'New Program',
      type: ProgramType.user,
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(programsProvider.notifier).addProgram(program);
    ref.read(programsProvider.notifier).setActiveProgram(program.id);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionsScreen(programId: program.id)),
    );
  }
}

class _ProgramCard extends ConsumerWidget {
  const _ProgramCard({required this.program});

  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = program.type == ProgramType.builtIn
        ? 'Built-in template'
        : 'Custom program';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: program.isActive
              ? const Icon(Icons.flag)
              : Text(
                  program.name.isEmpty ? '?' : program.name[0].toUpperCase(),
                ),
        ),
        title: Text(program.name),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ref.read(programsProvider.notifier).setActiveProgram(program.id);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionsScreen(programId: program.id),
            ),
          );
        },
      ),
    );
  }
}
