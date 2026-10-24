// Người phụ trách: Minh

class Combo {
  final String id;
  final String name;
  final String description;
  final int price;
  final String emoji;
  final String? tag; // "Bán chạy", "Tiết kiệm 18k"...

  const Combo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    this.tag,
  });
}

class SelectedCombo {
  final Combo combo;
  final int quantity;

  const SelectedCombo(this.combo, this.quantity);

  int get subtotal => combo.price * quantity;
}
