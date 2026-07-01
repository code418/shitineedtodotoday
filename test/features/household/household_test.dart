// test/features/household/household_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/household/domain/household.dart';

void main() {
  group('HouseholdMember', () {
    const alice = HouseholdMember(id: 'm1', name: 'Alice');

    test('round-trips through JSON', () {
      final json = alice.toJson();
      expect(json, {'id': 'm1', 'name': 'Alice'});
      final restored = HouseholdMember.fromJson(json);
      expect(restored, alice);
    });

    test('equality and hashCode', () {
      const a = HouseholdMember(id: 'm1', name: 'Alice');
      const b = HouseholdMember(id: 'm1', name: 'Alice');
      const c = HouseholdMember(id: 'm2', name: 'Bob');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('Household', () {
    const alice = HouseholdMember(id: 'm1', name: 'Alice');
    const bob = HouseholdMember(id: 'm2', name: 'Bob');

    test('empty has default name and no members', () {
      expect(Household.empty.name, 'Our home');
      expect(Household.empty.members, isEmpty);
    });

    test('round-trips through JSON', () {
      const h = Household(name: 'Our place', members: [alice, bob]);
      final json = h.toJson();
      final restored = Household.fromJson(json);
      expect(restored.name, 'Our place');
      expect(restored.members, [alice, bob]);
    });

    test('fromJson uses default name when key missing', () {
      final h = Household.fromJson({'members': []});
      expect(h.name, 'Our home');
    });

    test('fromJson salvages good members and skips malformed ones', () {
      // One well-formed member, plus entries that would previously throw and
      // take the WHOLE household (including the good member) down with them.
      final h = Household.fromJson({
        'name': 'Our place',
        'members': [
          {'id': 'm1', 'name': 'Alice'}, // good
          {'name': 'No Id'}, // missing id → skip
          {'id': '', 'name': 'Blank Id'}, // empty id → skip
          'not-a-map', // wrong shape → skip
          {'id': 'm2'}, // missing name → kept with ''
        ],
      });
      expect(h.name, 'Our place');
      expect(h.members, const [
        HouseholdMember(id: 'm1', name: 'Alice'),
        HouseholdMember(id: 'm2', name: ''),
      ]);
    });

    test('fromJson tolerates a non-list members field without throwing', () {
      final h = Household.fromJson({'name': 'X', 'members': 'oops'});
      expect(h.name, 'X');
      expect(h.members, isEmpty);
    });

    test('withMember appends a member', () {
      final h = Household.empty.withMember(alice);
      expect(h.members, [alice]);
    });

    test('withoutMember removes by id', () {
      final h = const Household(members: [alice, bob]).withoutMember('m1');
      expect(h.members, [bob]);
    });

    test('memberById returns correct member or null', () {
      const h = Household(members: [alice, bob]);
      expect(h.memberById('m1'), alice);
      expect(h.memberById('m99'), isNull);
      expect(h.memberById(null), isNull);
    });

    test('equality and hashCode', () {
      const a = Household(name: 'Home', members: [alice]);
      const b = Household(name: 'Home', members: [alice]);
      const c = Household(name: 'Home', members: [bob]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('copyWith overrides supplied fields only', () {
      const h = Household(name: 'Old', members: [alice]);
      final h2 = h.copyWith(name: 'New');
      expect(h2.name, 'New');
      expect(h2.members, [alice]);
    });
  });
}
