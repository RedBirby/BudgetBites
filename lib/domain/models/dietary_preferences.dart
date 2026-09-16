class DietaryPreferences {
  const DietaryPreferences({
    this.diets = const {},
    this.allergies = const {},
    this.goals = const {},
    this.exactMatches = false,
  });

  final Set<String> diets;
  final Set<String> allergies;
  final Set<String> goals;
  final bool exactMatches;

  static const dietOptions = <String>{
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Gluten-free',
    'Halal',
    'Kosher',
  };
  static const primaryDiets = <String>{'Vegetarian', 'Vegan', 'Pescatarian'};
  static const allergyOptions = <String>{
    'Peanuts',
    'Tree nuts',
    'Dairy',
    'Eggs',
    'Shellfish',
    'Soy',
  };
  static const goalOptions = <String>{
    'High protein',
    'Lower sodium',
    'Heart healthy',
    'Diabetes friendly',
  };

  bool get isEmpty => diets.isEmpty && allergies.isEmpty && goals.isEmpty;

  DietaryPreferences copyWith({
    Set<String>? diets,
    Set<String>? allergies,
    Set<String>? goals,
    bool? exactMatches,
  }) => DietaryPreferences(
    diets: diets ?? this.diets,
    allergies: allergies ?? this.allergies,
    goals: goals ?? this.goals,
    exactMatches: exactMatches ?? this.exactMatches,
  );

  Map<String, Object> toJson() => {
    'diets': diets.toList(),
    'allergies': allergies.toList(),
    'goals': goals.toList(),
    'exactMatches': exactMatches,
  };

  factory DietaryPreferences.fromJson(Map<String, dynamic> json) =>
      DietaryPreferences(
        diets: Set<String>.from(json['diets'] as List? ?? const []),
        allergies: Set<String>.from(json['allergies'] as List? ?? const []),
        goals: Set<String>.from(json['goals'] as List? ?? const []),
        exactMatches: json['exactMatches'] as bool? ?? false,
      );
}
