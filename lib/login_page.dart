import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_page.dart';
import 'main_menu.dart';
import 'lesson_card_page.dart';

// ============================================================
//  PAGE DE CONNEXION — تسجيل الدخول
// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // ── Contrôleurs ────────────────────────────────────────────
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Animation ──────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  //  CONNEXION
  // ============================================================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();

    final String? savedFirst = prefs.getString('firstName');
    final String? savedLast = prefs.getString('lastName');
    final String? savedPassword = prefs.getString('password');

    // Vérifie qu'un compte existe
    if (savedFirst == null || savedLast == null || savedPassword == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'لا يوجد حساب. يرجى إنشاء حساب أولاً';
      });
      return;
    }

    // Vérifie les informations
    final bool isValid = _firstNameCtrl.text.trim().toLowerCase() ==
            savedFirst.toLowerCase() &&
        _lastNameCtrl.text.trim().toLowerCase() == savedLast.toLowerCase() &&
        _passwordCtrl.text == savedPassword;

    if (isValid) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LessonCardPage(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'الاسم أو كلمة المرور غير صحيحة';
      });
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond dégradé ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF1976D2),
                ],
              ),
            ),
          ),

          // ── Cercles décoratifs ────────────────────────────────
          Positioned(
            top: -w * 0.2,
            right: -w * 0.2,
            child: Container(
              width: w * 0.7,
              height: w * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -w * 0.3,
            left: -w * 0.2,
            child: Container(
              width: w * 0.8,
              height: w * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // ── Contenu principal ─────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.08, vertical: h * 0.04),
                  child: Column(
                    children: [
                      SizedBox(height: h * 0.04),

                      // ── Titre ───────────────────────────────
                      Text(
                        'تسجيل الدخول',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: w * 0.07,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                offset: Offset(1, 2)),
                          ],
                        ),
                      ),

                      SizedBox(height: h * 0.04),

                      // ── Formulaire ──────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // الاسم
                              _buildField(
                                controller: _firstNameCtrl,
                                label: 'الاسم',
                                icon: Icons.person_outline,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'يرجى إدخال الاسم'
                                    : null,
                              ),

                              const SizedBox(height: 16),

                              // اللقب
                              _buildField(
                                controller: _lastNameCtrl,
                                label: 'اللقب',
                                icon: Icons.badge_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'يرجى إدخال اللقب'
                                    : null,
                              ),

                              const SizedBox(height: 16),

                              // كلمة المرور
                              _buildField(
                                controller: _passwordCtrl,
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                obscure: !_passwordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(() =>
                                      _passwordVisible = !_passwordVisible),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'يرجى إدخال كلمة المرور'
                                    : null,
                              ),

                              // Message d'erreur
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.red.shade300, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _errorMessage!,
                                          textDirection: TextDirection.rtl,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Amiri',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.error_outline,
                                          color: Colors.redAccent, size: 20),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // ── Bouton دخول ─────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD700),
                                    foregroundColor: const Color(0xFF0D47A1),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 4,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFF0D47A1),
                                          ),
                                        )
                                      : Text(
                                          'دخول',
                                          style: TextStyle(
                                            fontFamily: 'Amiri',
                                            fontSize: w * 0.055,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.04),

                      // ── Lien inscription ─────────────────────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const RegistrationPage(),
                            transitionDuration:
                                const Duration(milliseconds: 400),
                            transitionsBuilder: (_, animation, __, child) {
                              final tween = Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOutCubic));
                              return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child);
                            },
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_back_ios,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'ليس لديك حساب ؟  سجّل الآن',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: w * 0.042,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  WIDGET : Champ de texte stylisé
  // ============================================================
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: const TextStyle(
          color: Colors.white, fontFamily: 'Amiri', fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Amiri'),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent),
      ),
      validator: validator,
    );
  }
}
