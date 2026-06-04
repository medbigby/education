import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';
import 'lesson_card_page.dart';

// ============================================================
//  PAGE D'INSCRIPTION — إنشاء حساب
// ============================================================
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with TickerProviderStateMixin {
  // ── Contrôleurs ────────────────────────────────────────────
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ── State ──────────────────────────────────────────────────
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  String? _selectedGender;
  String? _photoPath;

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
    _ageCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  //  CHOISIR UNE PHOTO
  // ============================================================
  Future<void> _pickPhoto() async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1565C0),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر مصدر الصورة',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoSourceBtn(
                  icon: Icons.camera_alt,
                  label: 'الكاميرا',
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.camera);
                  },
                ),
                _photoSourceBtn(
                  icon: Icons.photo_library,
                  label: 'المعرض',
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _photoSourceBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'Amiri', fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (image != null) setState(() => _photoPath = image.path);
    } catch (e) {
      debugPrint('Image picker: $e');
    }
  }

  // ============================================================
  //  INSCRIPTION
  // ============================================================
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null) {
      _showSnack('يرجى اختيار الجنس');
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', _firstNameCtrl.text.trim());
    await prefs.setString('lastName', _lastNameCtrl.text.trim());
    await prefs.setInt('age', int.parse(_ageCtrl.text.trim()));
    await prefs.setString('gender', _selectedGender!);
    await prefs.setString('password', _passwordCtrl.text);
    if (_photoPath != null) {
      await prefs.setString('photoPath', _photoPath!);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LessonCardPage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _showSnack('تم إنشاء الحساب بنجاح ✅');
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 15)),
        backgroundColor: const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                  Color(0xFF1A237E),
                  Color(0xFF283593),
                  Color(0xFF303F9F),
                ],
              ),
            ),
          ),

          // ── Cercle décoratif ──────────────────────────────────
          Positioned(
            top: -w * 0.25,
            left: -w * 0.15,
            child: Container(
              width: w * 0.7,
              height: w * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // ── Contenu ──────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.07, vertical: h * 0.02),
                  child: Column(
                    children: [
                      // ── Bouton retour ───────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white70),
                        ),
                      ),

                      // ── Photo de profil ─────────────────────
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: w * 0.28,
                              height: w * 0.28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                                border: Border.all(
                                    color: const Color(0xFFFFD700), width: 2.5),
                                image: _photoPath != null
                                    ? DecorationImage(
                                        image: FileImage(File(_photoPath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _photoPath == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt,
                                            color: Colors.white70,
                                            size: w * 0.08),
                                        const SizedBox(height: 4),
                                        Text('الصورة',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontFamily: 'Amiri',
                                                fontSize: w * 0.03)),
                                      ],
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFD700),
                                ),
                                child: const Icon(Icons.edit,
                                    color: Color(0xFF0D47A1), size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Titre ───────────────────────────────
                      Text(
                        'إنشاء حساب جديد',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: w * 0.065,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Formulaire ──────────────────────────
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // ── الاسم ────────────────────────
                              _buildField(
                                controller: _firstNameCtrl,
                                label: 'الاسم',
                                icon: Icons.person_outline,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'يرجى إدخال الاسم'
                                    : null,
                              ),

                              const SizedBox(height: 14),

                              // ── اللقب ────────────────────────
                              _buildField(
                                controller: _lastNameCtrl,
                                label: 'اللقب',
                                icon: Icons.badge_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'يرجى إدخال اللقب'
                                    : null,
                              ),

                              const SizedBox(height: 14),

                              // ── العمر (champ texte) ───────────
                              _buildField(
                                controller: _ageCtrl,
                                label: 'العمر',
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'يرجى إدخال العمر';
                                  final age = int.tryParse(v.trim());
                                  if (age == null || age < 3 || age > 99)
                                    return 'يرجى إدخال عمر صحيح';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // ── الجنس ────────────────────────
                              _buildSectionLabel('الجنس'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _genderBtn(
                                      label: 'أنثى',
                                      icon: Icons.face_3,
                                      value: 'أنثى',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _genderBtn(
                                      label: 'ذكر',
                                      icon: Icons.face,
                                      value: 'ذكر',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // ── كلمة المرور ──────────────────
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
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'يرجى إدخال كلمة المرور';
                                  if (v.length < 6)
                                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // ── تأكيد كلمة المرور ────────────
                              _buildField(
                                controller: _confirmCtrl,
                                label: 'تأكيد كلمة المرور',
                                icon: Icons.lock_reset_outlined,
                                obscure: !_confirmPasswordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _confirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(() =>
                                      _confirmPasswordVisible =
                                          !_confirmPasswordVisible),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'يرجى تأكيد كلمة المرور';
                                  if (v != _passwordCtrl.text)
                                    return 'كلمة المرور غير متطابقة';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 26),

                              // ── Bouton تسجيل ─────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
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
                                          'تسجيل',
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
  //  WIDGET : Bouton genre
  // ============================================================
  Widget _genderBtn({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final bool selected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFD700) : Colors.white38,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? const Color(0xFF0D47A1) : Colors.white70,
                size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF0D47A1) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  WIDGET : Label de section
  // ============================================================
  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          color: Colors.white70,
          fontFamily: 'Amiri',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
