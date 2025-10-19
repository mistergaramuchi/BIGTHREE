import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session/models.dart';
import '../../domain/session/programs_provider.dart';
import '../../domain/session/session_templates_provider.dart';
import '../../ui/responsive/layout_constants.dart';
import 'session_overview_screen.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({required this.programId, super.key});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programByIdProvider(programId));
    if (program == null) {
      return const Scaffold(body: Center(child: Text('Program not found.')));
    }

    final templates = ref.watch(sessionTemplatesByProgramProvider(programId));

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          IconButton(
            tooltip: 'Edit program',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _promptEditProgram(context, ref, program),
          ),
          IconButton(
            tooltip: program.isActive ? 'Active program' : 'Set active',
            icon: Icon(program.isActive ? Icons.flag : Icons.flag_outlined),
            onPressed: () => ref
                .read(programsProvider.notifier)
                .setActiveProgram(program.id),
          ),
        ],
      ),
      body: Padding(
        padding: LayoutConstants.responsivePadding(context),
        child: LayoutConstants.maxWidthConstrained(
          child: ListView.separated(
            itemCount: templates.length + 1,
            separatorBuilder: (_, __) =>
                SizedBox(height: LayoutConstants.responsiveGap(context) / 2),
            itemBuilder: (context, index) {
              if (index == templates.length) {
                return _CreateSessionTile(
                  onCreate: () => _createSession(context, ref, program),
                );
              }

              final template = templates[index];
              return _SessionTemplateTile(template: template, program: program);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _createSession(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) async {
    final id = 'template_${DateTime.now().millisecondsSinceEpoch}';
    final template = SessionTemplate(
      id: id,
      programId: program.id,
      name: 'New Session',
      status: SessionStatus.draft,
      exercises: const [SessionOverviewScreen.defaultAccessoryExercise],
    );
    ref.read(sessionTemplatesProvider.notifier).addSession(template);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionOverviewScreen(
          baseTemplate: template,
          subtitle: 'Build your template and start when ready',
          canDeleteTemplate: true,
        ),
      ),
    );
  }

  Future<void> _promptEditProgram(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) async {
    final controller = TextEditingController(text: program.name);
    final isBuiltIn = program.type == ProgramType.builtIn;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Program'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Program name'),
          ),
          actions: [
            if (!isBuiltIn)
              TextButton(
                onPressed: () {
                  ref.read(programsProvider.notifier).removeProgram(program.id);
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
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(programsProvider.notifier)
                      .updateProgram(
                        program.copyWith(name: name, updatedAt: DateTime.now()),
                      );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _SessionTemplateTile extends ConsumerWidget {
  const _SessionTemplateTile({required this.template, required this.program});

  final SessionTemplate template;
  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = switch (template.status) {
      SessionStatus.draft => 'Draft',
      SessionStatus.active => 'Active',
      SessionStatus.done => 'Completed',
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            template.name.isEmpty ? '?' : template.name[0].toUpperCase(),
          ),
        ),
        title: Text(template.name),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionOverviewScreen(
                baseTemplate: template,
                subtitle: 'Review and customize before you start',
                canDeleteTemplate: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreateSessionTile extends StatelessWidget {
  const _CreateSessionTile({required this.onCreate});

  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: const Icon(Icons.add),
        ),
        title: const Text('Create Session'),
        subtitle: const Text('Build a new session for this program.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onCreate,
      ),
    );
  }
}
