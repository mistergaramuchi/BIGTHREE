import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_data.dart';
import 'models.dart';

final sessionTemplatesProvider =
    StateNotifierProvider<SessionTemplatesNotifier, List<SessionTemplate>>(
      (ref) => SessionTemplatesNotifier(),
    );

final sessionTemplatesByProgramProvider =
    Provider.family<List<SessionTemplate>, String>((ref, programId) {
      final templates = ref.watch(sessionTemplatesProvider);
      final filtered =
          templates
              .where((template) => template.programId == programId)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      return filtered;
    });

class SessionTemplatesNotifier extends StateNotifier<List<SessionTemplate>> {
  SessionTemplatesNotifier() : super(demoSessionTemplates);

  void addSession(SessionTemplate template) {
    final now = DateTime.now();
    final updatedTemplate = template.copyWith(updatedAt: now);
    final index = state.indexWhere((existing) => existing.id == template.id);
    if (index == -1) {
      state = [...state, updatedTemplate];
    } else {
      final updated = [...state];
      updated[index] = updatedTemplate;
      state = updated;
    }
  }

  void removeSession(String templateId) {
    state = state.where((template) => template.id != templateId).toList();
  }

  void removeByProgram(String programId) {
    state = state.where((template) => template.programId != programId).toList();
  }
}
