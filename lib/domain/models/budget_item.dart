class BudgetItem {
  const BudgetItem({
    required this.id,
    required this.name,
    this.price,
    this.checked = false,
  });
  final String id;
  final String name;
  final double? price;
  final bool checked;

  BudgetItem copyWith({String? name, double? price, bool? checked}) =>
      BudgetItem(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        checked: checked ?? this.checked,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'checked': checked,
  };
  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num?)?.toDouble(),
    checked: json['checked'] as bool? ?? false,
  );
}
