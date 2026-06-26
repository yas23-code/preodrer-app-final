import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../menu/providers/menu_provider.dart';
import '../providers/canteen_provider.dart';

class CanteensScreen extends ConsumerStatefulWidget {
  const CanteensScreen({super.key});

  @override
  ConsumerState<CanteensScreen> createState() => _CanteensScreenState();
}

class _CanteensScreenState extends ConsumerState<CanteensScreen> {
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  // Design tokens
  static const _yellow = Color(0xFFFFC107);
  static const _red = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/canteen-background.mp4',
    );
    try {
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.setVolume(0.0); // Muted background
      _videoController.play();
      if (mounted) {
        setState(() => _videoInitialized = true);
      }
    } catch (_) {
      // Video failed to load — fallback to gradient background
      if (mounted) setState(() => _videoInitialized = false);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canteensAsync = ref.watch(canteensProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A00),
      body: Stack(
        children: [
          // ── FULL-SCREEN VIDEO BACKGROUND ──────────────────────────
          Positioned.fill(
            child: _videoInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A0A00),
                          Color(0xFF3D1F00),
                          Color(0xFF5C2E00),
                        ],
                      ),
                    ),
                  ),
          ),

          // ── VIDEO GRADIENT OVERLAY (Removed for maximum brightness) ──

          // ── MAIN CONTENT ──────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── PREMIUM HEADER ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome 👋',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'What are you craving?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Yellow accent line
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _yellow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          color: _yellow, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Our Canteens',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── CANTEENS LIST ─────────────────────────────────────
                Expanded(
                  child: canteensAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: _yellow),
                    ),
                    error: (e, st) => Center(
                      child: Text(
                        'Failed to load canteens: $e',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    data: (canteens) {
                      if (canteens.isEmpty) {
                        return const Center(
                          child: Text(
                            'No canteens available right now.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white70,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: canteens.length,
                        itemBuilder: (context, index) {
                          final canteen = canteens[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildCanteenCard(context, ref, canteen),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanteenCard(BuildContext context, WidgetRef ref, canteen) {
    final isOpen = canteen.isOpen as bool;

    return GestureDetector(
      onTap: () {
        if (!isOpen) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This canteen is currently closed.'),
              backgroundColor: _red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
        ref.read(selectedCanteenIdProvider.notifier).select(canteen.id);
        context.push('/menu');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Canteen image
              Stack(
                children: [
                  if (canteen.imageUrl != null &&
                      (canteen.imageUrl as String).isNotEmpty)
                    Image.network(
                      canteen.imageUrl as String,
                      height: 175,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _PlaceholderImage(),
                    )
                  else
                    const _PlaceholderImage(),

                  // Open/Closed badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFB71C1C),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Text(
                        isOpen ? '🟢 Open' : '🔴 Closed',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Card body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            canteen.name as String,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C1A00),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13,
                                  color: Color(0xFFFFB300)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  (canteen.location as String?) ??
                                      'Campus Canteen',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow button
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? _yellow
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: isOpen ? Colors.black : Colors.black26,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D1F00), Color(0xFF6D3A00)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 64,
          color: Colors.white38,
        ),
      ),
    );
  }
}
