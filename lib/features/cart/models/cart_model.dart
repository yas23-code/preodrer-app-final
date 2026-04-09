import '../../menu/models/menu_item.dart';

class CartLine {
  final MenuItem item;
  final int quantity;

  const CartLine({
    required this.item,
    required this.quantity,
  });

  CartLine copyWith({MenuItem? item, int? quantity}) => CartLine(
        item: item ?? this.item,
        quantity: quantity ?? this.quantity,
      );
}

class CartState {
  final Map<String, CartLine> lines;

  const CartState({required this.lines});

  const CartState.empty() : lines = const <String, CartLine>{};

  int get itemCount =>
      lines.values.fold(0, (sum, line) => sum + line.quantity);

  double get totalAmount =>
      lines.values.fold(0, (sum, line) => sum + line.item.price * line.quantity);

  CartState copyWith({Map<String, CartLine>? lines}) =>
      CartState(lines: lines ?? this.lines);
}
