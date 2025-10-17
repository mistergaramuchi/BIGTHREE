import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_data.dart';
import 'session_template.dart';

final sessionTemplatesProvider =
    StateNotifierProvider<SessionTemplatesNotifier, List<SessionTemplate>>(
      (ref) => SessionTemplatesNotifier(),
    );

class SessionTemplatesNotifier extends StateNotifier<List<SessionTemplate>> {
  SessionTemplatesNotifier() : super(demoSessionTemplates);

  void addSession(SessionTemplate template) {
    state = [template, ...state];
  }
}
