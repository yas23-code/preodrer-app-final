import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../cart/providers/cart_controller.dart';
import '../providers/menu_provider.dart';
import '../../canteen/providers/canteen_provider.dart';
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../models/menu_item.dart';
import '../../../shared/widgets/customer_bottom_navbar.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  // Animation controllers for floating cart button
  late final AnimationController _fadeScaleCtrl;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _fadeScaleAnim;
  late final Animation<double> _bounceAnim;
  int _prevCartCount = 0;

  // Category list configuration
  final List<Map<String, String>> _categories = const [
    {
      'name': 'All',
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Burger',
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Pizza',
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Rolls',
      'image': 'https://images.unsplash.com/photo-1626700051175-6518c4793f4f?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Sandwich',
      'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Cold Coffee',
      'image': 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Momos',
      'image': 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Chinese',
      'image': 'https://images.unsplash.com/photo-1526318896980-cf78c088247c?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Pasta',
      'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Snacks',
      'image': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Maggie',
      'image': 'https://images.unsplash.com/photo-1612966608967-312ba5987233?auto=format&fit=crop&w=150&q=80',
    },
    {
      'name': 'Paratha',
      'image': 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?auto=format&fit=crop&w=150&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Fade+scale controller (300ms)
    _fadeScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeScaleAnim = CurvedAnimation(
      parent: _fadeScaleCtrl,
      curve: Curves.easeOutBack,
    );
    // Bounce controller (400ms) for count changes
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.92), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeScaleCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  // Get fallback food image if Supabase doesn't return one
  String _getFoodImage(MenuItem item, String? publicUrl) {
    if (publicUrl != null && publicUrl.isNotEmpty) return publicUrl;

    final name = item.name.toLowerCase();
    if (name.contains('coffee')) {
      return 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('roll')) {
      return 'https://images.unsplash.com/photo-1626700051175-6518c4793f4f?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('sandwich')) {
      return 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('burger')) {
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('momo')) {
      return 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('pasta')) {
      return 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('fries')) {
      return 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('maggi') || name.contains('maggie')) {
      return 'https://images.unsplash.com/photo-1612966608967-312ba5987233?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('paratha') || name.contains('parantha')) {
      return 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?auto=format&fit=crop&w=300&q=80';
    } else if (name.contains('pizza')) {
      return 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=300&q=80';
    }
    return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=300&q=80';
  }

  // Stable rating based on id hash
  double _getRating(MenuItem item) {
    final hash = item.id.hashCode.abs();
    return 4.0 + (hash % 10) / 10.0;
  }

  @override
  Widget build(BuildContext context) {
    final menuItemsAsync = ref.watch(menuItemsProvider);
    final currentCanteen = ref.watch(currentCanteenProvider);
    final cartState = ref.watch(cartControllerProvider).asData?.value;
    final totalItemsInCart = cartState?.itemCount ?? 0;

    final isClosed = currentCanteen != null && !currentCanteen.isOpen;

    // Trigger floating cart animations
    if (totalItemsInCart > 0 && _prevCartCount == 0) {
      _fadeScaleCtrl.forward();
    } else if (totalItemsInCart == 0 && _prevCartCount > 0) {
      _fadeScaleCtrl.reverse();
    }
    if (totalItemsInCart != _prevCartCount && totalItemsInCart > 0) {
      _bounceCtrl.forward(from: 0);
    }
    _prevCartCount = totalItemsInCart;

    // Design Tokens
    const backgroundColor = Color(0xFFFFF9EC);
    const primaryYellow = Color(0xFFFFC107);
    const accentRed = Color(0xFFE53935);
    const textPrimary = Color(0xFF222222);
    const textSecondary = Color(0xFF666666);
    const borderColor = Color(0xFFFFE082);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, size: 22, color: textPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Centered canteen name + location
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentCanteen?.name ?? 'Menu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (currentCanteen?.location != null &&
                            currentCanteen!.location!.isNotEmpty)
                          Text(
                            currentCanteen.location!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),


                ],
              ),
            ),

            // Thin divider line below header
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: borderColor,
            ),
            const SizedBox(height: 16),

            // ── SEARCH SECTION ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "What are you craving?" + capacity badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'What are you craving?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4F4E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_outlined,
                                size: 14, color: Color(0xFF2E7D32)),
                            SizedBox(width: 4),
                            Text(
                              '100 left',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search input + Search button
                  Row(
                    children: [
                      // Search input field
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFEEEEEE),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(Icons.search,
                                  color: textSecondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v.trim()),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Feed the hunger monster 👹',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: Color(0xFFBBBBBB),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Yellow Search button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchQuery = _searchController.text.trim();
                          });
                          FocusScope.of(context).unfocus();
                        },
                        child: Container(
                          height: 50,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            color: primaryYellow,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Search',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── CANTEEN CLOSED ─────────────────────────────────────────────
            if (isClosed)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'This canteen is currently closed.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ordering is disabled.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // ── CATEGORY FILTER ──────────────────────────────────────────
              SizedBox(
                height: 128,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final name = cat['name']!;
                    final isSelected = _selectedCategory == name;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = name),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? primaryYellow
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.07),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: cat['image']!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: const Color(0xFFEEEEEE),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: const Color(0xFFEEEEEE),
                                    child: const Icon(Icons.restaurant,
                                        size: 20,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? textPrimary
                                    : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ── MENU ITEMS LIST ──────────────────────────────────────────
              Expanded(
                child: menuItemsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFFFC107))),
                  error: (e, _) => Center(
                    child: Text('Failed to load menu: $e',
                        style: const TextStyle(fontFamily: 'Poppins')),
                  ),
                  data: (allItems) {
                    // Filter by category
                    List<MenuItem> items = allItems;
                    if (_selectedCategory != 'All') {
                      final cat = _selectedCategory.toLowerCase();
                      items = items
                          .where((item) =>
                              item.name.toLowerCase().contains(cat) ||
                              (item.description
                                      ?.toLowerCase()
                                      .contains(cat) ??
                                  false))
                          .toList();
                    }
                    // Filter by search query
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      items = items
                          .where((item) =>
                              item.name.toLowerCase().contains(q) ||
                              (item.description
                                      ?.toLowerCase()
                                      .contains(q) ??
                                  false))
                          .toList();
                    }

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 52,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'No items found',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final cartQty = cartState?.lines[item.id]?.quantity ?? 0;
                        final supabase = ref.read(supabaseClientProvider);
                        String? publicUrl;
                        if (item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty) {
                          publicUrl = supabase.storage
                              .from(kFoodImagesBucketName)
                              .getPublicUrl(item.imageUrl!);
                        }
                        final imageUrl = _getFoodImage(item, publicUrl);
                        final rating = _getRating(item);

                        return Container(
                          height: 115,
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFF5D76E),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),

                              // Food image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 80,
                                    height: 80,
                                    color: const Color(0xFFF5F5F5),
                                    child: const Icon(Icons.restaurant,
                                        color: Colors.grey),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: const Color(0xFFF5F5F5),
                                    child: const Icon(Icons.restaurant,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Right section
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Name
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // Rating row
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              size: 13,
                                              color: Color(0xFFFFC107)),
                                          const SizedBox(width: 3),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Thin divider
                                      Container(
                                        height: 0.8,
                                        color: const Color(0xFFEEEEEE),
                                      ),

                                      // Price + Add button
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '₹${item.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: accentRed,
                                            ),
                                          ),

                                          // Add / quantity button
                                          Container(
                                            height: 32,
                                            width: 90,
                                            decoration: BoxDecoration(
                                              color: primaryYellow,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: cartQty > 0
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          ref
                                                              .read(cartControllerProvider
                                                                  .notifier)
                                                              .decrementItem(
                                                                  item);
                                                        },
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        child: const Padding(
                                                          padding: EdgeInsets.symmetric(
                                                              horizontal: 9,
                                                              vertical: 7),
                                                          child: Icon(
                                                              Icons.remove,
                                                              size: 13,
                                                              color:
                                                                  textPrimary),
                                                        ),
                                                      ),
                                                      Text(
                                                        '$cartQty',
                                                        style: const TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: textPrimary,
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          ref
                                                              .read(cartControllerProvider
                                                                  .notifier)
                                                              .addItem(item);
                                                        },
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        child: const Padding(
                                                          padding: EdgeInsets.symmetric(
                                                              horizontal: 9,
                                                              vertical: 7),
                                                          child: Icon(
                                                              Icons.add,
                                                              size: 13,
                                                              color:
                                                                  textPrimary),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : GestureDetector(
                                                    onTap: () {
                                                      ref
                                                          .read(cartControllerProvider
                                                              .notifier)
                                                          .addItem(item);
                                                    },
                                                    behavior: HitTestBehavior
                                                        .opaque,
                                                    child: const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(Icons.add,
                                                            size: 13,
                                                            color: textPrimary),
                                                        SizedBox(width: 3),
                                                        Text(
                                                          'Add',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Poppins',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: textPrimary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 0),
      floatingActionButton: _buildFloatingCart(
        totalItemsInCart,
        const Color(0xFFE53935),
        const Color(0xFFFFC107),
        const Color(0xFF222222),
        context,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _buildFloatingCart(
    int count,
    Color red,
    Color yellow,
    Color textPrimary,
    BuildContext ctx,
  ) {
    if (count == 0 && !_fadeScaleCtrl.isAnimating && _fadeScaleCtrl.value == 0) {
      return null;
    }
    return FadeTransition(
      opacity: _fadeScaleAnim,
      child: ScaleTransition(
        scale: _fadeScaleAnim,
        child: ScaleTransition(
          scale: _bounceAnim,
          child: GestureDetector(
            onTap: () => ctx.go('/cart'),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  // Yellow badge
                  Positioned(
                    top: -4,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: yellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: count > 9 ? 8 : 10,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
