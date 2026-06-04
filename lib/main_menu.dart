import 'package:flutter/material.dart';

// ============================================================
//  MENU PRINCIPAL — حرف الباء
//
//  ► Intégration dans votre projet :
//
//  1. Placez ce fichier dans lib/main_menu.dart
//  2. Placez ba_letter_game.dart     dans lib/activity1/ba_letter_game.dart
//  3. Placez letter_position_game.dart dans lib/activity2/letter_position_game.dart
//
//  4. Dans votre lib/main.dart, remplacez MyApp par :
//
//     import 'main_menu.dart';
//     void main() => runApp(const RootApp());
//
//  Assets supplémentaires (optionnels mais recommandés) :
//    assets/images/menu_bg.png   ← fond du menu
//    assets/images/ba_logo.png   ← logo / illustration de la lettre ب
// ============================================================

// ► Import des deux activités — on importe uniquement les pages nécessaires
import 'ba_letter_game.dart' show BaLetterGamePage;
import 'letter_position_game.dart' show LetterPositionGamePage;

// ── Point d'entrée racine ────────────────────────────────────
class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تعلماتي الأولى',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Amiri'),
      home: const MainMenuPage(),
    );
  }
}

// ============================================================
//  PAGE DU MENU
// ============================================================
class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Fond ──────────────────────────────────────────
              Image.asset(
                'assets/images/menu_bg.png',
                fit: BoxFit.cover,
                // Fallback si l'image est absente
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D47A1),
                        Color(0xFF1565C0),
                        Color(0xFF1976D2)
                      ],
                    ),
                  ),
                ),
              ),

              // ── Overlay sombre pour lisibilité ────────────────
              Container(color: Colors.black.withOpacity(0.35)),

              // ── Contenu centré ────────────────────────────────
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lettre ب décorative
                    Container(
                      width: w * 0.28,
                      height: w * 0.28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          'ب',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: w * 0.14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                  color: Colors.black38,
                                  blurRadius: 8,
                                  offset: Offset(2, 3)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.025),

                    // Titre
                    Text(
                      'تعلم حرف الباء',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: w * 0.065,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                              color: Colors.black45,
                              blurRadius: 6,
                              offset: Offset(1, 2)),
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.055),

                    // ── Bouton Activité 1 ─────────────────────────
                    _ActivityButton(
                      number: '١',
                      title: 'هل يوجد حرف  ب',
                      subtitle: 'اضغط الزر الصحيح',
                      icon: Icons.search,
                      color: const Color(0xFF2E7D32),
                      width: w * 0.78,
                      onTap: () => Navigator.push(
                        context,
                        _slideRoute(const BaLetterGamePage()),
                      ),
                    ),

                    SizedBox(height: h * 0.025),

                    // ── Bouton Activité 2 ─────────────────────────
                    _ActivityButton(
                      number: '٢',
                      title: 'أين حرف الباء؟',
                      subtitle: 'ضع الطفل في مكانه الصحيح',
                      icon: Icons.drag_indicator,
                      color: const Color(0xFF6A1B9A),
                      width: w * 0.78,
                      onTap: () => Navigator.push(
                        context,
                        _slideRoute(const LetterPositionGamePage()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Transition : glissement depuis la droite
  PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}

// ============================================================
//  WIDGET : Bouton d'activité
// ============================================================
class _ActivityButton extends StatefulWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double width;
  final VoidCallback onTap;

  const _ActivityButton({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.width,
    required this.onTap,
  });

  @override
  State<_ActivityButton> createState() => _ActivityButtonState();
}

class _ActivityButtonState extends State<_ActivityButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: _pressed ? 6 : 14,
                offset: _pressed ? const Offset(0, 2) : const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Numéro de l'activité
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end, // aligné à droite (arabe)
                  children: [
                    Text(
                      widget.title,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 13,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Icône
              Icon(widget.icon,
                  color: Colors.white.withOpacity(0.85), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
