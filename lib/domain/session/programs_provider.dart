import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_data.dart';
import 'models.dart';
import 'session_templates_provider.dart';

final programsProvider = StateNotifierProvider<ProgramsNotifier, List<Program>>(
  (ref) => ProgramsNotifier(ref),
);

final activeProgramProvider = Provider<Program?>((ref) {
  final programs = ref.watch(programsProvider);
  if (programs.isEmpty) return null;
  for (final program in programs) {
    if (program.isActive) return program;
  }
  return programs.first;
});

final programByIdProvider = Provider.family<Program?, String>((ref, id) {
  final programs = ref.watch(programsProvider);
  for (final program in programs) {
    if (program.id == id) return program;
  }
  return null;
});

class ProgramsNotifier extends StateNotifier<List<Program>> {
  ProgramsNotifier(this._ref) : super(demoPrograms);

  final Ref _ref;

  void addProgram(Program program) {
    state = [...state, program];
  }

  void updateProgram(Program program) {
    final index = state.indexWhere((existing) => existing.id == program.id);
    if (index == -1) return;
    final updated = [...state];
    updated[index] = program;
    state = updated;
  }

  void removeProgram(String programId) {
    Program? removed;
    for (final program in state) {
      if (program.id == programId) {
        removed = program;
        break;
      }
    }
    final removedActive = removed?.isActive ?? false;
    state = state.where((program) => program.id != programId).toList();
    _ref.read(sessionTemplatesProvider.notifier).removeByProgram(programId);
    if (removedActive && state.isNotEmpty) {
      setActiveProgram(state.first.id);
    }
  }

  void setActiveProgram(String programId) {
    final now = DateTime.now();
    state = [
      for (final program in state)
        program.copyWith(
          isActive: program.id == programId,
          updatedAt: program.id == programId ? now : program.updatedAt,
        ),
    ];
  }
}
