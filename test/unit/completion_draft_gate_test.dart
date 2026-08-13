import 'package:ayutam/features/timer/application/completion_draft_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('failed draft persist does not invoke save or resume', () async {
    var saveInvoked = false;
    var resumeInvoked = false;

    final saved = await afterSuccessfulDraftPersist(
      persistDraft: () async => false,
      action: () async => saveInvoked = true,
    );
    final resumed = await afterSuccessfulDraftPersist(
      persistDraft: () async => false,
      action: () async => resumeInvoked = true,
    );

    expect(saved, isFalse);
    expect(resumed, isFalse);
    expect(saveInvoked, isFalse);
    expect(resumeInvoked, isFalse);
  });

  test('successful draft persist invokes the follow-up action', () async {
    var saveInvoked = false;
    final saved = await afterSuccessfulDraftPersist(
      persistDraft: () async => true,
      action: () async => saveInvoked = true,
    );
    expect(saved, isTrue);
    expect(saveInvoked, isTrue);
  });
}
