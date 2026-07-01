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

/// Pure-Dart shallow equality for [HouseholdMember] lists, replacing the
/// Flutter-only `listEquals` so this domain class stays platform-agnostic.
bool _listEquals(List<HouseholdMember> a, List<HouseholdMember> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
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

  factory Household.fromJson(Map<String, dynamic> json) {
    // Decode defensively: one malformed member entry (missing id, wrong shape,
    // or a `members` field that isn't even a list) must not throw and take the
    // whole household — and its owner's other members — down with it. Salvage
    // every well-formed member and skip the rest, mirroring the skip-bad-doc
    // policy used for tasks/occurrences (see core/util/firestore_decode.dart).
    final rawMembers = json['members'];
    final members = <HouseholdMember>[
      if (rawMembers is List)
        for (final m in rawMembers)
          if (m is Map && m['id'] is String && (m['id'] as String).isNotEmpty)
            HouseholdMember(
              id: m['id'] as String,
              name: m['name'] is String ? m['name'] as String : '',
            ),
    ];
    return Household(
      name: json['name'] as String? ?? 'Our home',
      members: members,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Household &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _listEquals(members, other.members);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(members));

  @override
  String toString() => 'Household(name: $name, members: $members)';
}
