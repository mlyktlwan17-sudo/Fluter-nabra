import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ClinicalClinicScreen extends StatefulWidget {
  const ClinicalClinicScreen({Key? key}) : super(key: key);

  @override
  State<ClinicalClinicScreen> createState() => _ClinicalClinicScreenState();
}

class _ClinicalClinicScreenState extends State<ClinicalClinicScreen> {
  String ageGroup = 'طفل (من 3 إلى 12 سنة)';
  String primaryIssue = 'التأتأة وصعوبة انسياب الكلام';
  String severity = 'متوسط';
  final _storyController = TextEditingController();

  bool isLoading = false;
  Map<String, dynamic>? _clinicResult;

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitConsultation() async {
    setState(() {
      isLoading = true;
      _clinicResult = null;
    });

    final result = await ApiService.submitClinicConsultation(
      ageGroup: ageGroup,
      primaryIssue: primaryIssue,
      patientStory: _storyController.text.trim().isNotEmpty ? _storyController.text.trim() : 'لا يوجد تفاصيل إضافية مضافة.',
      severity: severity,
    );

    setState(() {
      isLoading = false;
      _clinicResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021B15),
      appBar: AppBar(
        title: Text('العيادة الرقمية الاستعجالية الطارئة', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF042D24),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: Colors.cyanAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'عرض تشخيصي فوري يضم ثلاثة خبراء: (الخبير اللساني، المعالج الأرطوفوني، والأخصائي النفس لغوي).',
                        style: GoogleFonts.cairo(color: Colors.grey[200], fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form inputs
              Text('اختر الفئة العمرية للمريض:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.only(right: 14, left: 14),
                decoration: BoxDecoration(color: const Color(0xFF042D24), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF042D24),
                    value: ageGroup,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF10B981)),
                    isExpanded: true,
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                    items: <String>['طفل (من 3 إلى 12 سنة)', 'مراهق (من 13 إلى 18 سنة)', 'بالغ (أكبر من 18 سنة)']
                        .map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newVal) => setState(() => ageGroup = newVal!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('المشكلة الصوتية والنطقية الأساسية:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.only(right: 14, left: 14),
                decoration: BoxDecoration(color: const Color(0xFF042D24), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF042D24),
                    value: primaryIssue,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF10B981)),
                    isExpanded: true,
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                    items: <String>[
                      'التأتأة وصعوبة انسياب الكلام',
                      'لثغة الحروف الـمختلفة (مثل الراء غين، أو السين ثاء)',
                      'الفأفأة والتردد اللفظي اللساني',
                      'تأخر وصعوبة مخارج الألفاظ العامة عند حديثي النطق',
                      'مخاوف ورهاب التحدث في المجامع العامة وصوت مهتز'
                    ].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newVal) => setState(() => primaryIssue = newVal!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('قصة الحالة وتفاصيل المشكلة (تحليل عائلتكم في المنزل):', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              TextField(
                controller: _storyController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF042D24),
                  hintText: 'اكتب قصة المريض بالتفصيل، كيف يعبر في حواره، متى تزداد الصعوبة وما تكرار المشكلة بالبيت...',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF074537)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('مستوى شدة العرض اللفظي الملاحظ:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              Row(
                children: ['خفيف', 'متوسط', 'طبي صلب حاد'].map((sev) {
                  final isSelected = severity == sev;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => severity = sev),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0B5C44) : const Color(0xFF03261F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFF074537)),
                        ),
                        child: Text(
                          sev,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: isLoading ? null : _handleSubmitConsultation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF021B15),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF021B15)))
                    : const Icon(Icons.local_hospital_rounded),
                label: Text('رفع استشارة طبية ذكية فورية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 30),

              // Results Container
              if (_clinicResult != null) ...[
                Text('🩺 التقرير الطبي والتشخيص التشاركي الصادر:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF042D24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Diagnostic summary
                      _buildReviewSec('التشخيص العلمي المشترك للكادر الطبي:', _clinicResult!['diagnosticSummary'], Colors.amber),
                      const Divider(color: Color(0xFF074537)),

                      // 2. Experts
                      _buildReviewSec('🤓 رأي الخبير اللساني (مخارج وصوتيات):', _clinicResult!['linguisticExpertReview'], Colors.tealAccent),
                      const SizedBox(height: 12),
                      _buildReviewSec('👩‍⚕️ رأي الأخصائي الأرطوفوني (علاج الكلام حركياً):', _clinicResult!['speechTherapistReview'], Colors.emeraldAccent),
                      const SizedBox(height: 12),
                      _buildReviewSec('🧠 رأي المعالج النفسي اللغوي (عقد الخوف ونفسية النطق):', _clinicResult!['psychologistReview'], Colors.cyanAccent),
                      const Divider(color: Color(0xFF074537)),

                      // 3. Week schedule plan
                      if ((_clinicResult!['weeksPlan'] as List).isNotEmpty) ...[
                        Text('📅 الخطة العلاجية والتمارين المنزلية المقترحة:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                        const SizedBox(height: 6),
                        ...(_clinicResult!['weeksPlan'] as List).map((plan) => Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFF021B15), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan['weekNum']!, style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('الهدف: ${plan['goal']}', style: GoogleFonts.cairo(color: Colors.tealAccent, fontSize: 10)),
                                  Text('التمارين والأنشطة: ${plan['activities']}', style: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 10)),
                                ],
                              ),
                            )),
                        const Divider(color: Color(0xFF074537)),
                      ],

                      // 4. Prognosis
                      Text('🔮 التوقع الطبي وقابلية الشفاء التام:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      Text(_clinicResult!['prognosisAndStatus'] ?? '', style: GoogleFonts.cairo(color: Colors.grey[200], fontSize: 11, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSec(String header, String? body, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(header, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.black, color: color)),
        const SizedBox(height: 4),
        Text(body ?? '', style: GoogleFonts.cairo(color: Colors.grey[200], fontSize: 11, height: 1.4)),
      ],
    );
  }
}
