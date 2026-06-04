import 'package:flutter/material.dart';
import 'main_menu.dart';

// ============================================================
//  LESSON CARD PAGE — بطاقة الدرس
//  Affichée après le login.
//  Un tap sur la carte → MainMenuPage
//
//  La carte reproduit fidèlement l'image :
//    ┌──────────────────────────────────────────┐
//    │  [ 8 ]   أَسْمَعُ ب          الأهداف    │
//    │          (titre)          - يُعَيِّن صَوتاً│
//    │                           - يَستَعمِل... │
//    └──────────────────────────────────────────┘
//  Fond violet/bordeaux — coins arrondis
// ============================================================
class LessonCardPage extends StatefulWidget {
  const LessonCardPage({super.key});

  @override
  State<LessonCardPage> createState() => _LessonCardPageState();
}

class _LessonCardPageState extends State<LessonCardPage>
    with SingleTickerProviderStateMixin {

  // Animation fade-in de la page
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  // Animation scale du tap sur la carte
  bool _cardPressed = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Navigation → MainMenuPage ────────────────────────────
  void _goToMenu() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainMenuPage(),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end:   Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity:  animation,
            child:    SlideTransition(
                position: animation.drive(tween), child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      // Fond sombre derrière la carte
      backgroundColor: const Color(0xFF1A1A2E),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── Fond dégradé doux ──────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                  ],
                ),
              ),
            ),

            // ── Carte centrée ──────────────────────────────────
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: GestureDetector(
                  onTapDown:   (_) => setState(() => _cardPressed = true),
                  onTapUp:     (_) { setState(() => _cardPressed = false); _goToMenu(); },
                  onTapCancel: ()  => setState(() => _cardPressed = false),
                  child: AnimatedScale(
                    scale:    _cardPressed ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child:    _buildCard(w, h),
                  ),
                ),
              ),
            ),

            // ── Indicateur "tap pour continuer" ───────────────
            Positioned(
              bottom: h * 0.08,
              left:   0,
              right:  0,
              child: Column(
                children: [
                  Icon(Icons.touch_app,
                      color: Colors.white.withOpacity(0.45), size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على البطاقة للمتابعة',
                    textDirection: TextDirection.rtl,
                    textAlign:     TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize:   w * 0.038,
                      color:      Colors.white.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ============================================================
  //  WIDGET : La carte de leçon
  // ============================================================
  Widget _buildCard(double w, double h) {
    // Couleurs de la carte (violet bordeaux comme l'image)
    const Color cardBg      = Color(0xFF6B2D5E);   // fond principal
    const Color cardBgLight = Color(0xFF7B3D6E);   // légère variation

    return Container(
      width:   w * 0.88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [cardBg, cardBgLight],
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset:     const Offset(0, 10),
          ),
          BoxShadow(
            color:      const Color(0xFF6B2D5E).withOpacity(0.35),
            blurRadius: 16,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(w * 0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── Numéro 8 ──────────────────────────────────────
            _buildNumberBadge(w),

            SizedBox(width: w * 0.04),

            // ── Titre central : أَسْمَعُ ب ─────────────────────
            Expanded(
              child: Text(
                'أَسْمَعُ ب',
                textAlign:     TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily:  'Amiri',
                  fontSize:    w * 0.075,
                  fontWeight:  FontWeight.w900,
                  color:       Colors.white,
                  shadows: const [
                    Shadow(
                        color:      Colors.black38,
                        blurRadius: 6,
                        offset:     Offset(1, 2)),
                  ],
                ),
              ),
            ),

            SizedBox(width: w * 0.04),

            // ── Bloc الأهداف ──────────────────────────────────
            _buildObjectivesBlock(w),

          ],
        ),
      ),
    );
  }

  // ── Badge numéro 8 ─────────────────────────────────────────
  Widget _buildNumberBadge(double w) {
    return Container(
      width:  w * 0.13,
      height: w * 0.13,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '8',
          style: TextStyle(
            fontFamily:  'Amiri',
            fontSize:    w * 0.07,
            fontWeight:  FontWeight.w900,
            color:       const Color(0xFF6B2D5E),
          ),
        ),
      ),
    );
  }

  // ── Bloc objectifs ──────────────────────────────────────────
  Widget _buildObjectivesBlock(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize:       MainAxisSize.min,
      children: [

        // Titre "الأهداف" souligné
        Text(
          'الأهداف',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily:  'Amiri',
            fontSize:    w * 0.038,
            fontWeight:  FontWeight.bold,
            color:       Colors.white,
            decoration:  TextDecoration.underline,
            decorationColor: Colors.white,
          ),
        ),

        SizedBox(height: w * 0.015),

        // Objectif 1
        _buildObjectiveLine(w, 'يُعَيِّن صَوتاً في كَلِمة.'),

        SizedBox(height: w * 0.008),

        // Objectif 2
        _buildObjectiveLine(w, 'يَستَعمِل مُفرَدات.'),
      ],
    );
  }

  Widget _buildObjectiveLine(double w, String text) {
    return Row(
      mainAxisSize:     MainAxisSize.min,
      textDirection:    TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize:   w * 0.030,
            color:      Colors.white.withOpacity(0.90),
            height:     1.4,
          ),
        ),
        SizedBox(width: w * 0.015),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '-',
            style: TextStyle(
              color:    Colors.white.withOpacity(0.90),
              fontSize: w * 0.030,
            ),
          ),
        ),
      ],
    );
  }
}
