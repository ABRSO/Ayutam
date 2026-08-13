/// Persist the completion draft first; only then Save Session or Resume.
///
/// Returns `false` without invoking [action] when [persistDraft] fails.
Future<bool> afterSuccessfulDraftPersist({
  required Future<bool> Function() persistDraft,
  required Future<void> Function() action,
}) async {
  if (!await persistDraft()) return false;
  await action();
  return true;
}
