import 'dart:developer' as developer;

/// Decodes Firestore documents defensively.
///
/// Maps each `(id, data)` pair through [fromJson] (injecting `id`), but a single
/// document that fails to parse is skipped and logged rather than thrown — so
/// one malformed/partial doc loses only itself instead of erroring the whole
/// `snapshots()` stream and blanking the user's entire list. Mirrors the
/// server-side defensiveness in `functions/src/reminder.ts` `prefsFromDoc`.
List<T> decodeDocs<T>(
  Iterable<(String id, Map<String, dynamic> data)> docs,
  T Function(Map<String, dynamic> json) fromJson, {
  required String label,
}) {
  final out = <T>[];
  for (final (id, data) in docs) {
    try {
      out.add(fromJson({...data, 'id': id}));
    } catch (e, st) {
      developer.log(
        'Skipping unparseable $label "$id"',
        name: 'snitd',
        error: e,
        stackTrace: st,
      );
    }
  }
  return out;
}
