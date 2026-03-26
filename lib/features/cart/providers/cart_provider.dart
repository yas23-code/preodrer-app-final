import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  int get itemCount => lines.values.fold(0, (sum, line) => sum + line.quantity);

  double get totalAmount =>
      lines.values.fold(0, (sum, line) => sum + line.item.price * line.quantity);

  CartState copyWith({Map<String, CartLine>? lines}) =>
      CartState(lines: lines ?? this.lines);
}

final cartControllerProvider =
    NotifierProvider<CartController, CartState>(CartController.new);

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState.empty();

  void addItem(MenuItem item) {
    final existing = state.lines[item.id];
    if (existing == null) {
      final nextLines = {...state.lines, item.id: CartLine(item: item, quantity: 1)};
      state = state.copyWith(lines: nextLines);
      return;
    }

    final nextLines = {
      ...state.lines,
      item.id: existing.copyWith(quantity: existing.quantity + 1),
    };
    state = state.copyWith(lines: nextLines);
  }

  void decrementItem(MenuItem item) {
    final existing = state.lines[item.id];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      final nextLines = {...state.lines}..remove(item.id);
      state = state.copyWith(lines: nextLines);
      return;
    }

    final nextLines = {
      ...state.lines,
      item.id: existing.copyWith(quantity: existing.quantity - 1),
    };
    state = state.copyWith(lines: nextLines);
  }

  void removeItem(MenuItem item) {
    final nextLines = {...state.lines}..remove(item.id);
    state = state.copyWith(lines: nextLines);
  }

  void clear() {
    state = const CartState.empty();
  }
}

