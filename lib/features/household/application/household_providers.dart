import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/application/tasks_providers.dart';
import '../data/household_repository.dart';
import '../domain/household.dart';

/// Streams the owner's household definition (empty if not signed in).
final householdProvider = StreamProvider<Household>((ref) {
  final uid = ref.watch(currentOwnerIdProvider);
  if (uid == null) return Stream.value(Household.empty);
  return ref.watch(householdRepositoryProvider).watch(uid);
});

/// Controller for household CRUD — null when there is no signed-in owner.
class HouseholdController {
  HouseholdController({
    required this.repository,
    required this.ownerId,
    required this.idGen,
  });

  final HouseholdRepository repository;
  final String ownerId;
  final String Function() idGen;

  Future<void> addMember(Household current, String name) => repository.save(
    ownerId,
    current.withMember(HouseholdMember(id: idGen(), name: name.trim())),
  );

  Future<void> removeMember(Household current, String id) =>
      repository.save(ownerId, current.withoutMember(id));

  Future<void> rename(Household current, String name) =>
      repository.save(ownerId, current.copyWith(name: name.trim()));
}

/// Provides a [HouseholdController], or null when there's no signed-in owner.
final householdControllerProvider = Provider<HouseholdController?>((ref) {
  final uid = ref.watch(currentOwnerIdProvider);
  if (uid == null) return null;
  return HouseholdController(
    repository: ref.watch(householdRepositoryProvider),
    ownerId: uid,
    idGen: () => 'm_${DateTime.now().microsecondsSinceEpoch}',
  );
});
