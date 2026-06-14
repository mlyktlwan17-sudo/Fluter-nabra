import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import 'login_screen.dart';
import 'diacritizer_screen.dart';
import 'speech_instructor_screen.dart';
import 'clinical_clinic_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = 'صالح بن غانم';
  String userEmail = 'demo@nabrah.io';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'صالح بن غانم';
      userEmail = prefs.getString('user_email') ?? 'demo@nabrah.io';
      isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF021B15),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF021B15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF042D24),
        elevation: 0,
        title: Text(
          'نَـبْــرَة - لوحة التحكم الجوالة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.black,
            fontSize: 16,
            color: const Color(0xFFF3EFE0),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.amber, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    backgroundColor: const Color(0xFF042D24),
                    title: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: Text('هل تود تسجيل الخروج من التطبيق ومسح التذكرة المحلية؟', style: GoogleFonts.cairo(color: Colors.grey[200])),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.tealAccent)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleLogout();
                        },
                        child: Text('خروج', style: GoogleFonts.cairo(color: Colors.amber)),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Greeting Banner
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF053B2D), Color(0xFF03261D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0C5642)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                          radius: 24,
                          child: Text(
                            userName.substring(0, 1),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً بك، $userName ✨',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'حساب مستخدم نشط: $userEmail',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF0C5642), height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('التمارين', '14', Icons.mic_rounded, Colors.emeraldAccent),
                        _buildStatItem('مستوى الدقة', '93%', Icons.legend_toggle_rounded, Colors.amberAccent),
                        _buildStatItem('الاستشارات', '3', Icons.healing_rounded, Colors.cyanAccent),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title Section for stats
              Text(
                '📈 منحنى تطور الأداء الصوتي اللفظي:',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF3EFE0),
                ),
              ),
              const SizedBox(height: 12),

              // Chart Container
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF042D24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF074637)),
                ),
                padding: const EdgeInsets.only(top: 24, bottom: 12, right: 16, left: 16),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey[800]!,
                        strokeWidth: 0.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            String name = '';
                            switch (value.toInt()) {
                              case 1:
                                name = 'فحص 1';
                                break;
                              case 2:
                                name = 'فحص 2';
                                break;
                              case 3:
                                name = 'تمرن 1';
                                break;
                              case 4:
                                name = 'تمرن 2';
                                break;
                              case 5:
                                name = 'الأخير';
                                break;
                            }
                            return Text(
                              name,
                              style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold),
                            );
                          },
                          interval: 1.0,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value % 25 == 0) {
                              return Text(
                                '%${value.toInt()}',
                                style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 9),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          interval: 25.0,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0.8,
                    maxX: 5.2,
                    minY: 40,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          const FlSpot(1, 55),
                          const FlSpot(2, 74),
                          const FlSpot(3, 82),
                          const FlSpot(4, 88),
                          const FlSpot(5, 93),
                        ],
                        isCurved: true,
                        color: const Color(0xFF10B981),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF021B15),
                            strokeColor: const Color(0xFF10B981),
                            strokeWidth: 2,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF10B981).withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Feature Launchpad
              Text(
                '🛠️ الخدمات وعيادات التشخيص الفوري:',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF3EFE0),
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _buildMenuCard(
                    context,
                    title: 'التشكيل والناطق الذكي',
                    desc: 'ضبط أواخر الحركات وتوليد الصوت',
                    icon: Icons.subtitles_rounded,
                    color: const Color(0xFF10B981),
                    targetScreen: const DiacritizerScreen(),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'محلل التلاوة والنطق',
                    desc: 'فحص الحروف وتسجيلها عضلات النطق',
                    icon: Icons.keyboard_voice_rounded,
                    color: Colors.amber,
                    targetScreen: const SpeechInstructorScreen(),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'العيادة الرقمية التشاركية',
                    desc: 'رأي الخبير اللساني وعلم النفس',
                    icon: Icons.healing_rounded,
                    color: Colors.cyan,
                    targetScreen: const ClinicalClinicScreen(),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'تقارير الأداء اللفظي',
                    desc: 'سجلات تاريخ الدرجات وتطور اللثغات',
                    icon: Icons.assessment_rounded,
                    color: Colors.pinkAccent,
                    onTap: () {
                      _showReportsBottomSheet(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        Text(title, style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 10)),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    Widget? targetScreen,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        if (targetScreen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
        } else if (onTap != null) {
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF042D24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF074537)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 18,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: Colors.grey[400],
                    fontSize: 9,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showReportsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF042D24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Text(
                    '📋 سجل وعيادة الفحوصات السابقة',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _buildReportRow('فحص نطق - الآية الكريمة (سورة الإخلاص)', 'النسبة المتكاملة: 93%', 'أمس في 04:12 مساءً', Colors.emerald),
              const SizedBox(height: 12),
              _buildReportRow('تمرين إلقاء - جمل لغوية للتخلص من اللثغة', 'النسبة المتكاملة: 88%', 'قبل يومين', Colors.teal),
              const SizedBox(height: 12),
              _buildReportRow('تشخيص العيادة الاستشارية الطارئة', 'الشدة: متوسطة', '11 يونيو 2026', Colors.cyan),
              const SizedBox(height: 12),
              _buildReportRow('فحص عجمة لغوية أولية', 'النسبة المتكاملة: 55%', '09 يونيو 2026', Colors.amber),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String title, String score, String date, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF031E18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF063A2E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          Row(
            children: [
              Container(width: 4, height: 32, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(date, style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 9)),
                ],
              ),
            ],
          ),
          Text(score, style: GoogleFonts.cairo(color: accent, fontSize: 11, fontWeight: FontWeight.black)),
        ],
      ),
    );
  }
}
