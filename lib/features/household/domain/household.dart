import 'package:flutter/foundation.dart';

/// A person in the household who takes a turn on shared chores.
class HouseholdMember {
  const HouseholdMember({required this.id, required this.name});

  /// Local member id — not necessarily a real account uid.
  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory HouseholdMember.fromJson(Map<String, dynamic> json) =>
      HouseholdMember(id: json['id'] as String, name: json['name'] as String);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'HouseholdMember(id: $id, name: $name)';
}

/// The set of people who share chores in this household.
class Household {
  const Household({this.name = 'Our home', this.members = const []});

  final String name;
  final List<HouseholdMember> members;

  static const empty = Household();

  Household copyWith({String? name, List<HouseholdMember>? members}) =>
      Household(name: name ?? this.name, members: members ?? this.members);

  Household withMember(HouseholdMember m) => copyWith(members: [...members, m]);

  Household withoutMember(String id) =>
      copyWith(members: members.where((m) => m.id != id).toList());

  HouseholdMember? memberById(String? id) {
    if (id == null) return null;
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'members': [for (final m in members) m.toJson()],
  };

  factory Household.fromJson(Map<String, dynamic> json) => Household(
    name: json['name'] as String? ?? 'Our home',
    members: [
      for (final m in (json['members'] as List? ?? []))
        HouseholdMember.fromJson(m as Map<String, dynamic>),
    ],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Household &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          listEquals(members, other.members);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(members));

  @override
  String toString() => 'Household(name: $name, members: $members)';
}
