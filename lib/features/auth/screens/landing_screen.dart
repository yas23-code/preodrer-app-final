import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late VideoPlayerController _bgController;
  late VideoPlayerController _heroController;
  bool _isBgVideoInitialized = false;
  bool _isHeroVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initBgVideo();
    _initHeroVideo();
  }

  Future<void> _initBgVideo() async {
    try {
      _bgController = VideoPlayerController.asset('assets/videos/canteen-background.mp4');
      await _bgController.initialize();
      _bgController.setVolume(0);
      _bgController.setLooping(true);
      _bgController.play();
      debugPrint('BG video initialized: ${_bgController.value.size}');
      if (mounted) {
        setState(() => _isBgVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('BG video init error: $e');
    }
  }

  Future<void> _initHeroVideo() async {
    try {
      _heroController = VideoPlayerController.asset('assets/videos/hero-video.mp4');
      await _heroController.initialize();
      _heroController.setVolume(0);
      _heroController.setLooping(true);
      _heroController.play();
      debugPrint('Hero video initialized: ${_heroController.value.size}');
      if (mounted) {
        setState(() => _isHeroVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Hero video init error: $e');
    }
  }

  @override
  void dispose() {
    if (_isBgVideoInitialized) _bgController.dispose();
    if (_isHeroVideoInitialized) _heroController.dispose();
    super.dispose();
  }

  void _launchWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/917065909150?text=Hello%20preorder.food%20Support,%20I%20need%20help');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background while video loads
      body: Stack(
        children: [
          // Background Video
          if (_isBgVideoInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                   width: _bgController.value.size.width,
                   height: _bgController.value.size.height,
                   child: VideoPlayer(_bgController),
                ),
              ),
            ),
          
          // Removed overlay — video plays at full original brightness

          // Content
          Positioned.fill(
             child: SafeArea(
               bottom: false,
               child: SingleChildScrollView(
                 child: Column(
                   children: [
                     _buildNavBar(context),
                     _buildHeroSection(context),
                   ],
                 ),
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo placeholder
          Container(
             width: 38,
             height: 38,
             decoration: const BoxDecoration(
               shape: BoxShape.circle,
               color: Colors.white,
             ),
             child: ClipOval(
               child: Image.asset(
                 'assets/images/logo.png',
                 fit: BoxFit.cover,
               ),
             ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(children: [
              TextSpan(
                text: 'pre',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              TextSpan(
                text: 'order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDA291C), // mcd-red
                  fontFamily: 'Poppins',
                ),
              ),
            ]),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                   colors: [Color(0xFFDA291C), Color(0xFFFFC300)], // red to yellow
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
       color: Colors.transparent,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.center,
         children: [
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             decoration: BoxDecoration(
               color: Colors.white.withValues(alpha: 0.95),
               borderRadius: BorderRadius.circular(30),
               border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: const [
                 Icon(Icons.auto_awesome, size: 16, color: Color(0xFFDA291C)),
                 SizedBox(width: 8),
                 Text(
                   'Campus food, simplified',
                   style: TextStyle(
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                     color: Colors.black,
                   ),
                 ),
               ],
             ),
           ),
           const SizedBox(height: 24),
           const Text(
               'Skip the Queue,',
               style: TextStyle(
                 fontSize: 40,
                 fontWeight: FontWeight.w900,
                 color: Colors.black,
                 height: 1.1,
               ),
               textAlign: TextAlign.center,
             ),
           const Text(
             'Grab Your Food',
             style: TextStyle(
               fontSize: 40,
               fontWeight: FontWeight.w900,
               color: Color(0xFFFFC300), // mcd-yellow
               height: 1.1,
               shadows: [
                  Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
               ],
             ),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 32),
           
           // Hero Video
           if (_isHeroVideoInitialized)
             Container(
               width: double.infinity,
               constraints: const BoxConstraints(maxWidth: 500),
               child: AspectRatio(
                 aspectRatio: 16 / 9,
                 child: Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 4),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.3),
                         blurRadius: 20,
                         offset: const Offset(0, 10),
                       )
                     ],
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(12),
                     child: VideoPlayer(_heroController),
                   ),
                 ),
               ),
             ),

           const SizedBox(height: 32),
           const Text(
              'Order from your favorite campus canteens, pay ahead, and pick up when ready.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 260),
              child: GestureDetector(
                 onTap: () => context.go('/login'),
                 child: Container(
                   padding: const EdgeInsets.symmetric(vertical: 14),
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(
                       begin: Alignment.centerLeft,
                       end: Alignment.centerRight,
                       colors: [Color(0xFFFFB300), Color(0xFFDA291C)],
                     ),
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [
                       BoxShadow(
                          color: const Color(0xFFDA291C).withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                       )
                     ],
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: const [
                       Text(
                         'Get Started',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.w600,
                           color: Colors.white,
                           letterSpacing: 0.5,
                         ),
                       ),
                       SizedBox(width: 8),
                       Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                     ],
                   ),
                 ),
              ),
            ),
         ],
       ),
    );
  }




}
