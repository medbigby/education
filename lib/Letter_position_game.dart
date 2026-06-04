import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'main_menu.dart' show MainMenuPage;

// ============================================================
//  JEU 2 : Positionnement de la lettre "ب" — Drag & Drop
// ============================================================

enum LetterPos { bidaya, wasat, nihaya }

extension LetterPosLabel on LetterPos {
  String get label {
    switch (this) {
      case LetterPos.bidaya:
        return 'بداية';
      case LetterPos.wasat:
        return 'وسط';
      case LetterPos.nihaya:
        return 'نهاية';
    }
  }
}

class GameWord {
  final String word;
  final LetterPos correctPos;
  const GameWord({required this.word, required this.correctPos});
}

class GameGroup {
  final String bgImage;
  final List<int> childIds;
  final List<GameWord> words;
  const GameGroup({
    required this.bgImage,
    required this.childIds,
    required this.words,
  });
}

const List<GameGroup> kGroups = [
  GameGroup(
    bgImage: 'assets/images/2.png',
    childIds: [1, 2, 3],
    words: [
      GameWord(word: 'دب', correctPos: LetterPos.nihaya),
      GameWord(word: 'بيت', correctPos: LetterPos.bidaya),
      GameWord(word: 'كبش', correctPos: LetterPos.wasat),
    ],
  ),
  GameGroup(
    bgImage: 'assets/images/3.png',
    childIds: [4, 5, 6],
    words: [
      GameWord(word: 'مبراة', correctPos: LetterPos.wasat),
      GameWord(word: 'بطريق', correctPos: LetterPos.bidaya),
      GameWord(word: 'حليب', correctPos: LetterPos.nihaya),
    ],
  ),
  GameGroup(
    bgImage: 'assets/images/4.png',
    childIds: [7, 8, 9],
    words: [
      GameWord(word: 'قبعة', correctPos: LetterPos.wasat),
      GameWord(word: 'اب', correctPos: LetterPos.nihaya),
      GameWord(word: 'برج', correctPos: LetterPos.bidaya),
    ],
  ),
];

LetterPos _roleOf(int childId) {
  final mod = ((childId - 1) % 3);
  if (mod == 0) return LetterPos.bidaya;
  if (mod == 1) return LetterPos.wasat;
  return LetterPos.nihaya;
}

class ChildState {
  final int id;
  final LetterPos role;
  bool isPlaced;
  bool isSeated;

  ChildState({required this.id, required this.role})
      : isPlaced = false,
        isSeated = false;

  String get standingAsset => 'assets/images/enfant$id.png';
  String get seatedAsset => 'assets/images/enfant${id}assis.png';
  String get currentAsset => isSeated ? seatedAsset : standingAsset;
}

enum ActivityTwoPhase { playing, showResult, finished }

enum ResultType { none, win, sad }

class LetterPositionGamePage extends StatefulWidget {
  const LetterPositionGamePage({super.key});

  @override
  State<LetterPositionGamePage> createState() => _LetterPositionGamePageState();
}

class _LetterPositionGamePageState extends State<LetterPositionGamePage>
    with TickerProviderStateMixin {
  int _groupIndex = 0;
  int _wordIndex = 0;
  int _score = 0;

  // ── Phase ──────────────────────────────────────────────────
  ActivityTwoPhase _phase = ActivityTwoPhase.playing;
  ResultType _resultType = ResultType.none;
  int _resultKey = 0;

  // ── INTRO ──────────────────────────────────────────────────
  bool _isIntro = true; // true → affiche 1.png + joue ba2.mp3
  StreamSubscription? _introAudioSub; // écoute la fin de ba2.mp3

  // ── Enfants ────────────────────────────────────────────────
  late List<ChildState> _children;

  final Map<LetterPos, int?> _chair = {
    LetterPos.bidaya: null,
    LetterPos.wasat: null,
    LetterPos.nihaya: null,
  };

  // ── Audio ──────────────────────────────────────────────────
  final AudioPlayer _audio = AudioPlayer();
  Timer? _resultTimer;

  // ── Animation ──────────────────────────────────────────────
  late AnimationController _wordFadeCtrl;
  late Animation<double> _wordFadeAnim;

  late AnimationController _sitCtrl;
  late Animation<double> _sitAnim;

  // ============================================================
  //  INIT
  // ============================================================
  @override
  void initState() {
    super.initState();

    _wordFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _wordFadeAnim =
        CurvedAnimation(parent: _wordFadeCtrl, curve: Curves.easeIn);

    _sitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _sitAnim = CurvedAnimation(parent: _sitCtrl, curve: Curves.easeOutBack);

    // ► Lance l'intro au lieu de _initRound()
    _startIntro();
  }

  @override
  void dispose() {
    _introAudioSub?.cancel(); // ► annule l'écoute intro
    _wordFadeCtrl.dispose();
    _sitCtrl.dispose();
    _audio.dispose();
    _resultTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  //  INTRO : joue ba2.mp3 + affiche 1.png
  //  Le jeu démarre automatiquement à la fin de l'audio
  // ============================================================
  Future<void> _startIntro() async {
    try {
      await _audio.play(AssetSource('audio/Ba2.mp3'));
    } catch (e) {
      debugPrint('Audio intro: $e');
    }

    // Démarre le jeu à la fin de ba2.mp3
    _introAudioSub = _audio.onPlayerComplete.listen((_) {
      if (_isIntro && mounted) {
        _introAudioSub?.cancel();
        setState(() => _isIntro = false);
        _initRound();
      }
    });

    // Sécurité 7s si l'audio ne se déclenche pas
    Future.delayed(const Duration(seconds: 7), () {
      if (_isIntro && mounted) {
        setState(() => _isIntro = false);
        _initRound();
      }
    });
  }

  // ============================================================
  //  INITIALISATION D'UN ROUND (nouveau mot)
  // ============================================================
  void _initRound() {
    _chair[LetterPos.bidaya] = null;
    _chair[LetterPos.wasat] = null;
    _chair[LetterPos.nihaya] = null;

    final group = kGroups[_groupIndex];
    _children = group.childIds.map((id) {
      return ChildState(id: id, role: _roleOf(id));
    }).toList();

    _wordFadeCtrl.reset();
    _wordFadeCtrl.forward();
    _sitCtrl.reset();
  }

  // ============================================================
  //  DROP
  // ============================================================
  void _onDrop(ChildState child, LetterPos chairPos) {
    if (_chair[chairPos] != null || child.isPlaced) return;

    HapticFeedback.lightImpact();

    setState(() {
      child.isPlaced = true;
      child.isSeated = true;
      _chair[chairPos] = child.id;
    });

    _sitCtrl.reset();
    _sitCtrl.forward();

    Future.delayed(const Duration(milliseconds: 450), _validateDrop);
  }

  // ============================================================
  //  VALIDATION
  // ============================================================
  void _validateDrop() {
    if (!mounted) return;

    final GameWord currentWord = kGroups[_groupIndex].words[_wordIndex];
    final LetterPos correct = currentWord.correctPos;
    final int? occupantId = _chair[correct];

    bool isCorrect = false;
    if (occupantId != null) {
      final ChildState placed = _children.firstWhere((c) => c.id == occupantId);
      isCorrect = placed.role == correct;
    } else {
      final anyPlaced = _children.any((c) => c.isPlaced);
      if (!anyPlaced) return;
      isCorrect = false;
    }

    setState(() {
      _resultType = isCorrect ? ResultType.win : ResultType.sad;
      _phase = ActivityTwoPhase.showResult;
      _resultKey++;
      if (isCorrect) _score++;
    });

    _playAudio(isCorrect ? 'audio/audio_success.mp3' : 'audio/audio_fail.mp3');

    if (!isCorrect) HapticFeedback.mediumImpact();

    _resultTimer = Timer(const Duration(milliseconds: 2500), _advance);
  }

  // ============================================================
  //  AVANCER
  // ============================================================
  void _advance() {
    if (!mounted) return;

    final nextWord = _wordIndex + 1;
    final nextGroup = _groupIndex + 1;

    if (nextWord < kGroups[_groupIndex].words.length) {
      setState(() {
        _wordIndex = nextWord;
        _phase = ActivityTwoPhase.playing;
        _resultType = ResultType.none;
      });
      _initRound();
    } else if (nextGroup < kGroups.length) {
      setState(() {
        _groupIndex = nextGroup;
        _wordIndex = 0;
        _phase = ActivityTwoPhase.playing;
        _resultType = ResultType.none;
      });
      _initRound();
    } else {
      setState(() => _phase = ActivityTwoPhase.finished);
    }
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
            // ── 1. FOND FIXE : 1.png (toujours visible) ───────
            _buildFixedBackground(),

            // ── 2. FOND GROUPE : caché pendant l'intro ─────────
            if (!_isIntro && _phase == ActivityTwoPhase.playing)
              _buildGroupBackground(),

            // ── 3. MOT SUR LE TABLEAU : caché pendant l'intro ──
            if (!_isIntro && _phase == ActivityTwoPhase.playing)
              _buildChalkboardWord(w, h),

            // ── 4. CHAISES : cachées pendant l'intro ───────────
            if (!_isIntro && _phase == ActivityTwoPhase.playing)
              _buildChairs(w, h),

            // ── 5. ENFANTS : cachés pendant l'intro ────────────
            if (!_isIntro && _phase == ActivityTwoPhase.playing)
              _buildChildren(w, h),

            // ── 6. SCORE : caché pendant l'intro ───────────────
            if (!_isIntro) _buildScore(w),

            // ── 6b. BOUTON QUITTER ──────────────────────────────
            if (!_isIntro) _buildQuitButton(),

            // ── 7. RÉSULTAT ────────────────────────────────────
            if (_phase == ActivityTwoPhase.showResult) _buildResult(w),

            // ── 8. FIN ────────────────────────────────────────
            if (_phase == ActivityTwoPhase.finished) _buildFinish(w, h),
          ],
        );
      }),
    );
  }

  // ============================================================
  //  FOND FIXE — 1.png
  // ============================================================
  Widget _buildFixedBackground() {
    return SizedBox.expand(
      child: Image.asset(
        'assets/images/1.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
            ),
          ),
          child: const Center(
            child: Text('1.png', style: TextStyle(color: Colors.white54)),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  FOND GROUPE — 2/3/4.png
  // ============================================================
  Widget _buildGroupBackground() {
    final String bgPath = kGroups[_groupIndex].bgImage;

    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: SizedBox.expand(
          key: ValueKey(bgPath),
          child: Image.asset(
            bgPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.transparent,
              child: Center(
                child:
                    Text(bgPath, style: const TextStyle(color: Colors.white30)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  MOT SUR LE TABLEAU
  // ============================================================
  Widget _buildChalkboardWord(double w, double h) {
    final String word = kGroups[_groupIndex].words[_wordIndex].word;

    return Positioned(
      top: h * 0.09,
      left: w * 0.10,
      width: w * 0.60,
      child: FadeTransition(
        opacity: _wordFadeAnim,
        child: Text(
          word,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: w * 0.13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [
              Shadow(
                  color: Colors.black54, blurRadius: 8, offset: Offset(3, 3)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  CHAISES
  // ============================================================
  Widget _buildChairs(double w, double h) {
    const double chairTop = 0.20;
    const double chairSize = 0.18;

    final positions = [
      [0.16, LetterPos.bidaya],
      [0.36, LetterPos.wasat],
      [0.54, LetterPos.nihaya],
    ];

    return Stack(
      fit: StackFit.expand,
      children: positions.map((p) {
        final double left = w * (p[0] as double);
        final LetterPos chairPos = p[1] as LetterPos;
        return Positioned(
          left: left,
          top: h * chairTop,
          width: w * chairSize,
          height: h * 0.18,
          child: _buildOneChair(w, h, chairPos),
        );
      }).toList(),
    );
  }

  Widget _buildOneChair(double w, double h, LetterPos pos) {
    final int? occupantId = _chair[pos];
    final bool isOccupied = occupantId != null;

    return DragTarget<ChildState>(
      onWillAcceptWithDetails: (d) => !isOccupied && !d.data.isPlaced,
      onAcceptWithDetails: (d) => _onDrop(d.data, pos),
      builder: (ctx, candidates, _) {
        final bool hovering = candidates.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovering ? const Color(0xFFFFD700) : Colors.transparent,
              width: hovering ? 3 : 2,
            ),
            color:
                hovering ? Colors.yellow.withOpacity(0.22) : Colors.transparent,
            boxShadow: hovering
                ? [
                    BoxShadow(
                        color: Colors.yellow.withOpacity(0.45), blurRadius: 16)
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.50),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: Text(
                  pos.label,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              isOccupied
                  ? Expanded(
                      child: ScaleTransition(
                        scale: _sitAnim,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/enfant${occupantId}assis.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: Colors.green.shade300,
                              size: w * 0.08,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: Icon(
                        Icons.chair_alt,
                        color: hovering
                            ? Colors.white.withOpacity(0.9)
                            : Colors.transparent,
                        size: w * 0.08,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  //  ENFANTS DRAGGABLES
  // ============================================================
  Widget _buildChildren(double w, double h) {
    const double childTop = 0.37;

    return Positioned(
      top: h * childTop,
      left: w * 0.10,
      right: w * 0.02,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _children.map((c) => _buildDraggableChild(c, w, h)).toList(),
      ),
    );
  }

  Widget _buildDraggableChild(ChildState child, double w, double h) {
    final double size = w * 0.24;

    if (child.isPlaced) {
      return SizedBox(width: size, height: size * 1.3);
    }

    final widget = _childCard(child, size, w);

    return Draggable<ChildState>(
      data: child,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.12,
          child: _childCard(child, size, w, dragging: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: widget),
      child: widget,
    );
  }

  Widget _childCard(ChildState child, double size, double w,
      {bool dragging = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size * 1.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: dragging ? Colors.white.withOpacity(0.95) : Colors.transparent,
        border: Border.all(
          color: dragging ? const Color(0xFFFFD700) : Colors.transparent,
          width: dragging ? 2.5 : 1.5,
        ),
        boxShadow: dragging
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
              child: Image.asset(
                child.standingAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              child.role.label,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.028,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  RÉSULTAT
  // ============================================================
  Widget _buildResult(double w) {
    final String gif = _resultType == ResultType.win
        ? 'assets/images/win.gif'
        : 'assets/images/sad.gif';
    final String label =
        _resultType == ResultType.win ? 'أحسنت! ✅' : 'حاول مجدداً ❌';
    final Color color = _resultType == ResultType.win
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SizedBox.expand(
          key: ValueKey('result_$_resultKey'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(gif,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        color: color,
                        child: Center(
                          child: Icon(
                            _resultType == ResultType.win
                                ? Icons.emoji_events
                                : Icons.sentiment_dissatisfied,
                            color: Colors.white,
                            size: w * 0.18,
                          ),
                        ),
                      )),
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: EdgeInsets.only(top: w * 0.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    label,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: w * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  // ── Dialogue de confirmation quitter ─────────────────────────
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
  Widget _buildFinish(double w, double h) {
    final int total = kGroups.fold(0, (s, g) => s + g.words.length);
    final double percent = _score / total;

    return Container(
      color: Colors.black.withOpacity(0.80),
      child: Center(
        child: Container(
          width: w * 0.82,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black45, blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              percent >= 0.7 ? Icons.emoji_events : Icons.school,
              size: 72,
              color: percent >= 0.7
                  ? const Color(0xFFFFC107)
                  : const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            const Text('انتهى الدرس',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                    color: Color(0xFF333333))),
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

            // ── Bouton retour menu (fin du dernier jeu) ───────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainMenuPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('القائمة الرئيسية',
                    style: TextStyle(fontSize: 16, fontFamily: 'Amiri')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
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
    _introAudioSub?.cancel(); // ► annule l'écoute intro
    setState(() {
      _isIntro = true; // ► repart en intro
      _groupIndex = 0;
      _wordIndex = 0;
      _score = 0;
      _phase = ActivityTwoPhase.playing;
      _resultType = ResultType.none;
      _resultKey = 0;
    });
    _startIntro(); // ► rejoue ba2.mp3 + attend la fin
  }
}
