import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'main_menu.dart' show MainMenuPage;
import 'letter_position_game.dart' show LetterPositionGamePage;

// ============================================================
//  MINI-JEU : Apprentissage de la lettre arabe "ب"
//  VERSION FINALE : Images interactives + cercle à colorier
//
//  ► ASSETS :
//    assets/images/classroom_assis.png      ← fond intro
//    assets/images/classroom_normal.png     ← fond normal
//    assets/images/classroom_waiting.gif    ← attente choix
//    assets/images/classroom_celebrate.gif  ← bonne réponse
//    assets/images/classroom_failed.gif     ← mauvaise réponse
//    assets/images/lapin.png    livre.png   perroquet.png
//    assets/images/port.png     raisin.png  vache.png
//    assets/images/telephone.png  TV.png
//    assets/audio/audio_intro.mp3  audio_success.mp3
//    assets/audio/Lapin.mp3   Livre.mp3   perroquet.mp3
//    assets/audio/Port.mp3    Raisin.mp3  Vache.mp3
//    assets/audio/Telephone.mp3   TV.mp3
// ============================================================

// ============================================================
//  MODÈLE : une image du jeu
// ============================================================
class GameImage {
  final String name; // nom du fichier image (sans extension)
  final String audioName; // nom du fichier audio (sans extension, casse exacte)
  final bool hasBa; // true → contient "ب" → cercle à colorier

  const GameImage({
    required this.name,
    required this.audioName,
    required this.hasBa,
  });

  String get imagePath => 'assets/images/$name.png';
  String get audioPath => 'audio/$audioName.mp3';
}

// ── Liste des images ────────────────────────────────────────
const List<GameImage> kGameImages = [
  GameImage(name: 'lapin', audioName: 'Lapin', hasBa: true),
  GameImage(name: 'livre', audioName: 'Livre', hasBa: true),
  GameImage(name: 'perroquet', audioName: 'Perroquet', hasBa: true),
  GameImage(name: 'port', audioName: 'Port', hasBa: true),
  GameImage(name: 'raisin', audioName: 'Raisin', hasBa: true),
  GameImage(name: 'vache', audioName: 'Vache', hasBa: true),
  GameImage(name: 'telephone', audioName: 'Telephone', hasBa: false),
  GameImage(name: 'TV', audioName: 'TV', hasBa: false),
];

// ============================================================
//  MODÈLE : étiquette élève
// ============================================================
class StudentLabel {
  final String name;
  final String role;
  final double leftPct;
  final double topPct;
  final bool labelAbove;

  const StudentLabel({
    required this.name,
    required this.role,
    required this.leftPct,
    required this.topPct,
    this.labelAbove = true,
  });
}

const List<StudentLabel> kStudents = [
  StudentLabel(
      name: 'نجيب ',
      role: 'مصحح وملاحظ',
      leftPct: 0.28,
      topPct: 0.48,
      labelAbove: true),
  StudentLabel(
      name: 'نجيب ',
      role: 'باحث عن التفاصيل',
      leftPct: 0.54,
      topPct: 0.43,
      labelAbove: true),
  StudentLabel(
      name: 'حسن ',
      role: 'متأكد من الفهم',
      leftPct: 0.10,
      topPct: 0.63,
      labelAbove: true),
  StudentLabel(
      name: 'حسن ',
      role: 'مشجع',
      leftPct: 0.78,
      topPct: 0.63,
      labelAbove: true),
  StudentLabel(
      name: 'متوسط ',
      role: 'قارئ وملخص',
      leftPct: 0.30,
      topPct: 0.76,
      labelAbove: false),
  StudentLabel(
      name: 'متوسط ',
      role: 'مسجل',
      leftPct: 0.50,
      topPct: 0.76,
      labelAbove: false),
];

// ============================================================
//  ENUM phases
// ============================================================
enum ActivityOnePhase { introduction, playing, finished }

// ============================================================
//  PAGE PRINCIPALE
// ============================================================
class BaLetterGamePage extends StatefulWidget {
  const BaLetterGamePage({super.key});

  @override
  State<BaLetterGamePage> createState() => _BaLetterGamePageState();
}

class _BaLetterGamePageState extends State<BaLetterGamePage>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  ActivityOnePhase _phase = ActivityOnePhase.introduction;
  int _imageIndex = 0;
  int _score = 0;

  bool _isCelebrating = false;
  int _celebrationKey = 0;
  bool _isFailed = false;
  int _failedKey = 0;
  bool _isWaiting = false;

  /// true → le cercle est colorié (utilisateur a tapé dessus)
  bool _circleColored = false;

  /// true → bouton لا يوجد flashe en rouge
  bool _noButtonFlash = false;

  List<GameImage> _shuffled = [];

  // ── Audio ──────────────────────────────────────────────────
  final AudioPlayer _audio = AudioPlayer();
  StreamSubscription? _audioSub;

  // ── Animations ─────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  late AnimationController _buttonSlideCtrl;
  late Animation<Offset> _buttonSlideAnim;

  late AnimationController _circleCtrl;
  late Animation<double> _circleAnim;

  Timer? _resultTimer;

  // ============================================================
  //  INIT / DISPOSE
  // ============================================================
  @override
  void initState() {
    super.initState();
    _shuffled = List.from(kGameImages)..shuffle(Random());

    // Fondu image/texte tableau
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    // Boutons glissent depuis le bas
    _buttonSlideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _buttonSlideAnim = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _buttonSlideCtrl, curve: Curves.easeOutBack));

    // Animation du cercle quand il est colorié
    _circleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _circleAnim =
        CurvedAnimation(parent: _circleCtrl, curve: Curves.elasticOut);

    _startIntroduction();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _buttonSlideCtrl.dispose();
    _circleCtrl.dispose();
    _audio.dispose();
    _audioSub?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  //  PHASE 1 : INTRODUCTION
  //  Fond = classroom_assis.png + lettre "ب" + audio_intro
  //  Jeu BLOQUÉ jusqu'à fin de l'audio
  // ============================================================
  Future<void> _startIntroduction() async {
    _fadeCtrl.forward();
    await _playAudio('audio/audio_intro.mp3');

    // Annule toute souscription précédente
    _audioSub?.cancel();
    _audioSub = _audio.onPlayerComplete.listen((_) {
      if (_phase == ActivityOnePhase.introduction && mounted) {
        _audioSub?.cancel();
        _startGame();
      }
    });

    // Sécurité = durée RÉELLE de audio_intro.mp3 + 2s de marge
    // Remplacez 50 par la durée réelle de votre audio_intro.mp3
    Future.delayed(const Duration(seconds: 50), () {
      if (_phase == ActivityOnePhase.introduction && mounted) _startGame();
    });
  }

  // ============================================================
  //  PHASE 2 : JEU
  // ============================================================
  void _startGame() {
    if (!mounted) return;
    // Stoppe IMMÉDIATEMENT l'audio intro avant tout
    _audio.stop();
    _audioSub?.cancel();

    setState(() {
      _phase = ActivityOnePhase.playing;
      _imageIndex = 0;
      _isWaiting = true;
      _circleColored = false;
    });
    _buttonSlideCtrl.forward();
    _fadeCtrl.reset();
    _fadeCtrl.forward();

    _playImageAudio();
  }

  // ============================================================
  //  AUDIO DE L'IMAGE COURANTE
  //  Lance l'audio correspondant à l'image affichée
  // ============================================================
  Future<void> _playImageAudio() async {
    // Stoppe tout audio en cours
    await _audio.stop();

    // Délai pour laisser l'image s'afficher
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    if (_phase != ActivityOnePhase.playing) return;

    final String path = _shuffled[_imageIndex].audioPath;
    debugPrint('▶ Audio image : $path'); // ← vérifie dans la console

    await _playAudio(path);
  }

  // ============================================================
  //  BOUTON يوجد → colorie le cercle puis valide hasBa=true
  // ============================================================
  Future<void> _onYesButtonTapped() async {
    if (_phase != ActivityOnePhase.playing || _isCelebrating || _isFailed)
      return;
    if (_circleColored) return;

    HapticFeedback.lightImpact();

    // 1. Colorie le cercle avec animation
    setState(() => _circleColored = true);
    _circleCtrl.reset();
    _circleCtrl.forward();

    // 2. Laisse l'animation se voir (500 ms) puis valide
    await Future.delayed(const Duration(milliseconds: 500));
    _validateAnswer(answerHasBa: true);
  }

  // ============================================================
  //  INTERACTION : Cercle cliqué directement (même effet que يوجد)
  // ============================================================
  Future<void> _onCircleTapped() async {
    await _onYesButtonTapped();
  }

  // ============================================================
  //  BOUTON لا يوجد → valide hasBa=false
  // ============================================================
  Future<void> _onNoButtonTapped() async {
    if (_phase != ActivityOnePhase.playing || _isCelebrating || _isFailed)
      return;
    _validateAnswer(answerHasBa: false);
  }

  // ============================================================
  //  VALIDATION
  // ============================================================
  void _validateAnswer({required bool answerHasBa}) {
    if (!mounted) return;
    setState(() => _isWaiting = false);

    final bool isCorrect = _shuffled[_imageIndex].hasBa == answerHasBa;
    if (isCorrect) {
      _handleCorrect();
    } else {
      _handleWrong(answerHasBa);
    }
  }

  Future<void> _handleCorrect() async {
    setState(() {
      _score++;
      _isCelebrating = true;
      _celebrationKey++;
    });
    await _playAudio('audio/audio_success.mp3');
    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _isCelebrating = false);
      _nextImage();
    });
  }

  Future<void> _handleWrong(bool answerHasBa) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFailed = true;
      _failedKey++;
      _noButtonFlash =
          !answerHasBa; // flash rouge sur لا يوجد si c'est lui l'erreur
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _noButtonFlash = false);

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isFailed = false);

    await Future.delayed(const Duration(milliseconds: 200));
    _nextImage();
  }

  // ============================================================
  //  IMAGE SUIVANTE
  // ============================================================
  void _nextImage() {
    if (!mounted) return;
    final next = _imageIndex + 1;
    if (next >= _shuffled.length) {
      setState(() => _phase = ActivityOnePhase.finished);
      return;
    }
    _fadeCtrl.reset();
    _circleCtrl.reset();
    setState(() {
      _imageIndex = next;
      _isWaiting = true;
      _circleColored = false;
    });
    _fadeCtrl.forward();
    // Lance l'audio de la nouvelle image
    _playImageAudio();
  }

  // ============================================================
  //  AUDIO
  // ============================================================
  Future<void> _playAudio(String path) async {
    try {
      await _audio.stop();
      await _audio.play(AssetSource(path));
    } catch (e) {
      debugPrint('Audio: $e');
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Fond
            _buildBackground(w, h),

            // 2. Étiquettes élèves (seulement pendant le jeu)
            if (_phase == ActivityOnePhase.playing) _buildStudentLabels(w, h),

            // 3. Contenu tableau (lettre intro ou image+cercle)
            _buildChalkboardContent(w, h),

            // 4. Score
            if (_phase != ActivityOnePhase.introduction) _buildScore(w),

            // 4b. Bouton quitter (petit, haut droite)
            if (_phase != ActivityOnePhase.introduction) _buildQuitButton(),

            // 5. Deux boutons يوجد / لا يوجد (phase playing)
            if (_phase == ActivityOnePhase.playing) _buildAnswerButtons(w, h),

            // 6. Bouton "تخطي" (intro seulement)
            if (_phase == ActivityOnePhase.introduction) _buildSkipButton(),

            // 7. Fin
            if (_phase == ActivityOnePhase.finished) _buildFinishScreen(w, h),
          ],
        );
      }),
    );
  }

  // ============================================================
  //  FOND
  // ============================================================
  Widget _buildBackground(double w, double h) {
    // ── Intro : classroom_assis ────────────────────────────
    if (_phase == ActivityOnePhase.introduction) {
      return SizedBox.expand(
        child: Image.asset(
          'assets/images/classsroom_assis.png', // ✅ typo corrigée (3 "s" → 2)
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _fallback(w, const Color(0xFF4527A0), Icons.school),
        ),
      );
    }
    // ── Célébration ─────────────────────────────────────────
    if (_isCelebrating) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: SizedBox.expand(
          key: ValueKey('cel_$_celebrationKey'),
          child: Image.asset('assets/images/classroom_celebrate.gif',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _fallback(w, const Color(0xFF2E7D32), Icons.celebration)),
        ),
      );
    }
    // ── Attente ─────────────────────────────────────────────
    if (_isWaiting) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SizedBox.expand(
          key: const ValueKey('waiting'),
          child: Image.asset('assets/images/classroom_waiting.gif',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _fallback(w, const Color(0xFF37474F), Icons.hourglass_top)),
        ),
      );
    }
    // ── Échec ───────────────────────────────────────────────
    if (_isFailed) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: SizedBox.expand(
          key: ValueKey('fail_$_failedKey'),
          child: Image.asset('assets/images/classroom_failed.gif',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(w,
                  const Color(0xFFB71C1C), Icons.sentiment_very_dissatisfied)),
        ),
      );
    }
    // ── Normal ──────────────────────────────────────────────
    return SizedBox.expand(
      child: Image.asset('assets/images/classroom_normal.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _fallback(w, const Color(0xFF1565C0), Icons.school)),
    );
  }

  Widget _fallback(double w, Color c, IconData icon) => Container(
        color: c,
        child: Center(child: Icon(icon, color: Colors.white, size: w * 0.15)),
      );

  // ============================================================
  //  CONTENU DU TABLEAU
  //  Phase intro  → grande lettre "ب" centrée
  //  Phase playing → Row[ cercle gauche | image centrée ]
  // ============================================================
  Widget _buildChalkboardContent(double w, double h) {
    final double tbTop = h * 0.08;
    final double tbHeight = h * 0.27;
    final double tbLeft = w * 0.15;
    final double tbWidth = w * 0.65;

    // ── INTRO : lettre "ب" ────────────────────────────────────
    if (_phase == ActivityOnePhase.introduction) {
      return Positioned(
        top: tbTop,
        left: tbLeft,
        width: tbWidth,
        height: tbHeight,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: Text(
              'ب',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: w * 0.22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [
                  Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(3, 3)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── PLAYING : cercle (gauche) + image (droite) ────────────
    if (_phase == ActivityOnePhase.playing && _shuffled.isNotEmpty) {
      final GameImage current = _shuffled[_imageIndex];
      final double circleD = tbHeight * 0.22;

      return Positioned(
        top: tbTop,
        left: tbLeft,
        width: tbWidth,
        height: tbHeight,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: tbWidth * 0.02, vertical: tbHeight * 0.05),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Cercle cliquable ──────────────────────────
                AnimatedBuilder(
                  animation: _circleAnim,
                  builder: (_, __) {
                    return GestureDetector(
                      onTap: _onCircleTapped,
                      child: Container(
                        width: circleD,
                        height: circleD,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _circleColored
                              ? Color.lerp(Colors.white,
                                  const Color(0xFF1565C0), _circleAnim.value)
                              : Colors.white.withOpacity(0.15),
                          border: Border.all(
                            color: _circleColored
                                ? const Color(0xFF1565C0)
                                : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: _circleColored
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF1565C0)
                                          .withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2)
                                ]
                              : [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.20),
                                      blurRadius: 4)
                                ],
                        ),
                        child: _circleColored
                            ? Icon(Icons.check,
                                color: Colors.white, size: circleD * 0.55)
                            : null,
                      ),
                    );
                  },
                ),

                const SizedBox(width: 6),

                // ── Image de l'objet ──────────────────────────
                Expanded(
                  child: ClipRect(
                    child: Image.asset(
                      current.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              color: Colors.white54, size: w * 0.07),
                          const SizedBox(height: 4),
                          Text(current.name,
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: w * 0.028,
                                  fontFamily: 'Amiri')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  //  DEUX BOUTONS : يوجد (vert) et لا يوجد (rouge)
  // ============================================================
  Widget _buildAnswerButtons(double w, double h) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _buttonSlideAnim,
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 14, 16, MediaQuery.of(context).padding.bottom + 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.60),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // ── يوجد (vert) ───────────────────────────────
              Expanded(
                child: _answerBtn(
                  label: 'يوجد',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF2E7D32),
                  flashing: false,
                  screenW: w,
                  onTap: _onYesButtonTapped,
                ),
              ),
              const SizedBox(width: 12),
              // ── لا يوجد (rouge) ───────────────────────────
              Expanded(
                child: _answerBtn(
                  label: 'لا يوجد',
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFFC62828),
                  flashing: _noButtonFlash,
                  screenW: w,
                  onTap: _onNoButtonTapped,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _answerBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool flashing,
    required double screenW,
    required VoidCallback onTap,
  }) {
    final Color col = flashing ? Colors.red.shade900 : color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: col,
        borderRadius: BorderRadius.circular(18),
        border:
            flashing ? Border.all(color: Colors.red.shade200, width: 3) : null,
        boxShadow: [
          BoxShadow(
              color: col.withOpacity(0.50),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenW * 0.048,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  ÉTIQUETTES ÉLÈVES
  // ============================================================
  Widget _buildStudentLabels(double w, double h) {
    return Stack(
      fit: StackFit.expand,
      children: kStudents.map((s) {
        final double labelW = w * 0.34;
        final double left =
            (w * s.leftPct - labelW / 2).clamp(4.0, w - labelW - 4);
        final double top = s.labelAbove ? h * s.topPct - 58 : h * s.topPct + 6;
        return Positioned(
          left: left,
          top: top,
          width: labelW,
          child: _LabelBubble(name: s.name, role: s.role, above: s.labelAbove),
        );
      }).toList(),
    );
  }

  // ============================================================
  //  SCORE
  // ============================================================
  Widget _buildScore(double w) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          const Icon(Icons.star, color: Color(0xFFFFC107), size: 20),
          const SizedBox(width: 6),
          Text('$_score',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333))),
        ]),
      ),
    );
  }

  // ============================================================
  //  BOUTON PASSER INTRO
  // ============================================================
  Widget _buildSkipButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      right: 20,
      child: TextButton.icon(
        onPressed: _startGame,
        icon: const Icon(Icons.skip_next, color: Colors.white70),
        label: const Text('تخطي',
            style: TextStyle(color: Colors.white70, fontFamily: 'Amiri')),
        style: TextButton.styleFrom(
          backgroundColor: Colors.black38,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  // ============================================================
  //  BOUTON QUITTER — haut droite
  // ============================================================
  Widget _buildQuitButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 16,
      child: GestureDetector(
        onTap: _confirmQuit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.exit_to_app, color: Colors.white70, size: 18),
              const SizedBox(width: 5),
              Text(
                'خروج',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogue de confirmation quitter ────────────────────────
  Future<void> _confirmQuit() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'هل تريد الخروج؟',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Amiri', fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'سيتم فقدان تقدمك في هذه الجلسة.',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style:
              TextStyle(fontFamily: 'Amiri', fontSize: 15, color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء',
                style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    color: Color(0xFF2196F3))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('نعم، خروج',
                style: TextStyle(
                    fontFamily: 'Amiri', fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuPage()),
        (route) => false,
      );
    }
  }

  // ============================================================
  //  ÉCRAN DE FIN
  // ============================================================
  Widget _buildFinishScreen(double w, double h) {
    final int total = _shuffled.length;
    final double percent = _score / total;
    return Container(
      color: Colors.black.withOpacity(0.78),
      child: Center(
        child: Container(
          width: w * 0.82,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black45, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              percent >= 0.7
                  ? Icons.emoji_events
                  : Icons.sentiment_satisfied_alt,
              size: 72,
              color: percent >= 0.7
                  ? const Color(0xFFFFC107)
                  : const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            const Text(
              'انتهى الدرس',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 12),
            Text('$_score / $total',
                style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2196F3))),
            const SizedBox(height: 24),

            // ── Bouton rejouer ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _restartGame,
                icon: const Icon(Icons.replay),
                label: const Text('اعد الدرس',
                    style: TextStyle(fontSize: 16, fontFamily: 'Amiri')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Bouton jeu suivant ────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          const LetterPositionGamePage(),
                      transitionDuration: const Duration(milliseconds: 400),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('النشاط التالي',
                    style: TextStyle(fontSize: 16, fontFamily: 'Amiri')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Bouton retour menu ────────────────────────────
            TextButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainMenuPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_outlined, color: Colors.grey),
              label: const Text('القائمة الرئيسية',
                  style: TextStyle(
                      fontFamily: 'Amiri', fontSize: 15, color: Colors.grey)),
            ),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  //  REDÉMARRAGE
  // ============================================================
  void _restartGame() {
    _resultTimer?.cancel();
    _audioSub?.cancel();
    _circleCtrl.reset();
    _buttonSlideCtrl.reset();
    _fadeCtrl.reset();
    setState(() {
      _shuffled = List.from(kGameImages)..shuffle(Random());
      _imageIndex = 0;
      _score = 0;
      _isCelebrating = false;
      _celebrationKey = 0;
      _isFailed = false;
      _failedKey = 0;
      _isWaiting = false;
      _circleColored = false;
      _noButtonFlash = false;
      _phase = ActivityOnePhase.introduction;
    });
    _startIntroduction();
  }
}

// ============================================================
//  WIDGET : Bulle étiquette élève
// ============================================================
class _LabelBubble extends StatelessWidget {
  final String name;
  final String role;
  final bool above;

  const _LabelBubble({
    required this.name,
    required this.role,
    required this.above,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!above) _arrow(false),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.88),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontFamily: 'Amiri',
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(role,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontFamily: 'Amiri',
                      fontSize: 10)),
            ],
          ),
        ),
        if (above) _arrow(true),
      ],
    );
  }

  Widget _arrow(bool pointDown) => CustomPaint(
        size: const Size(14, 7),
        painter: _ArrowPainter(
          color: const Color(0xFF1A237E).withOpacity(0.88),
          pointDown: pointDown,
        ),
      );
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointDown;
  const _ArrowPainter({required this.color, required this.pointDown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.pointDown != pointDown;
}
