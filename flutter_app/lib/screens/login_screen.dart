import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    // Simulate login / register with persistence
    await Future.delayed(const Duration(milliseconds: 1200));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', _emailController.text);
    await prefs.setString(
      'user_name', 
      isLogin ? 'صالح بن غانم' : (_nameController.text.isNotEmpty ? _nameController.text : 'أخصائي نبرة الجديد'),
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021B15),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Identity
                  const Icon(
                    Icons.multitrack_audio_rounded,
                    size: 80,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نَـبْــرَة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 36,
                      fontWeight: FontWeight.black,
                      color: const Color(0xFFF3EFE0),
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    'تقويم الأداء الصوتي واللغوي العربي',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF34D399).withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Segment Controller
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF042D24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLogin = true),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isLogin ? const Color(0xFF0B5C44) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'تسجيل الدخول',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: isLogin ? Colors.white : Colors.tealAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLogin = false),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isLogin ? const Color(0xFF0B5C44) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'إنشاء حساب جديد',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: !isLogin ? Colors.white : Colors.tealAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Form Fields
                  if (!isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF05352A),
                        labelText: 'الاسم الكامل',
                        labelStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF10B981)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF074D3C)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF10B981)),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF05352A),
                      labelText: 'البريد الإلكتروني',
                      labelStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF10B981)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF074D3C)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF10B981)),
                      ),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                      if (!v.contains('@')) return 'يرجى إدخال بريد صالح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF05352A),
                      labelText: 'كلمة المرور',
                      labelStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF10B981)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF074D3C)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF10B981)),
                      ),
                    ),
                    validator: (v) => v!.length < 6 ? 'كلمة المرور يجب أن لا تقل عن 6 أحرف' : null,
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: const Color(0xFF021B15),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF021B15),
                            ),
                          )
                        : Text(
                            isLogin ? 'دخول فوري للمنصة' : 'متابعة التسجيل والتهيئة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Demo Notice
                  Text(
                    '🔐 تطبيق هاتف موحد للعيادة الرقمية لتقويم وعلاج النطق',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
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
