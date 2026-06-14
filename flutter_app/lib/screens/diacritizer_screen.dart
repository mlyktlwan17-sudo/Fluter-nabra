import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:audioplayers/audioplayers.dart';

class DiacritizerScreen extends StatefulWidget {
  const DiacritizerScreen({Key? key}) : super(key: key);

  @override
  State<DiacritizerScreen> createState() => _DiacritizerScreenState();
}

class _DiacritizerScreenState extends State<DiacritizerScreen> {
  final _textController = TextEditingController(
    text: "إن منصة نبرة صرح متكامل لتقويم اللسان العربي والتمكين اللفظي",
  );

  bool isLoading = false;
  bool isPlaying = false;
  String? diacritizedText;
  String? difficulty;
  List<dynamic> notes = [];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleDiacritize() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      diacritizedText = null;
      notes = [];
    });

    final result = await ApiService.diacritizeText(_textController.text.trim());

    setState(() {
      isLoading = false;
      if (result.containsKey('error') && result['error'] == true) {
        // Fallback or warning
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'فشل الاتصال بالذكاء الاصطناعي السحابي، تم تشغيل المشفِر المحلي لتبسيط العبارة.',
              style: GoogleFonts.cairo(fontSize: 12),
            ),
            backgroundColor: Colors.amber[900],
          ),
        );
      }
      diacritizedText = result['diacritizedText'];
      difficulty = result['difficulty'];
      notes = result['notes'] ?? [];
    });
  }

  Future<void> _handlePlayAudio() async {
    final textToSpeak = diacritizedText ?? _textController.text.trim();
    if (textToSpeak.isEmpty) return;

    setState(() {
      isPlaying = true;
    });

    final base64Audio = await ApiService.generateTts(textToSpeak);

    if (base64Audio != null) {
      try {
        final bytes = base64Decode(base64Audio);
        // Play directly via AudioPlayer using BytesSource
        await _audioPlayer.play(BytesSource(bytes));
      } catch (e) {
        _showNativeSpeechAnnouncement();
      }
    } else {
      _showNativeSpeechAnnouncement();
    }

    setState(() {
      isPlaying = false;
    });
  }

  void _showNativeSpeechAnnouncement() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تنبيه: لم يتمكن الخادم من صياغة الصوت مجاناً، جاري التوليد المحلي التكميلي (TTS).',
          style: GoogleFonts.cairo(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021B15),
      appBar: AppBar(
        title: Text('تشكيل النصوص والناطق الذكي', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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
              // Tips card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B5C44).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0B5C44).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'اكتب النص العربي أدناه لضبط حركات أواخر الكلمة وصحة النطق، ثم انقر تشكيل للحصول على تقطيع إعرابي وبنيوي دقيق.',
                        style: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 11),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Title label
              Text('أدخل النص الفصيح المراد ضبطه:', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),

              // Custom Input Field
              TextField(
                controller: _textController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF042D24),
                  hintText: 'مثال: وجعلنا من الماء كل شيء حي أفلا يؤمنون',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF074537)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actions Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _handleDiacritize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: const Color(0xFF021B15),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF021B15)))
                          : const Icon(Icons.flash_on, size: 18),
                      label: Text('تشكيل النص بالكامل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  if (diacritizedText != null) ...[
                    const SizedBox(width: 10),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: ElevatedButton.icon(
                        onPressed: isPlaying ? null : _handlePlayAudio,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: const Color(0xFF021B15),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: isPlaying
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF021B15)))
                            : const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text('استماع للناطق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 24),

              // Diacritized feedback card
              if (diacritizedText != null) ...[
                Text('🔮 النص العربي بعد الضبط الإعرابي والتشكيل الكامل:', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03261F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(
                        diacritizedText!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF3EFE0),
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFF074537)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('مجمع النطق الصوتي العربي للغرف الذكية', style: GoogleFonts.cairo(color: Colors.grey[550], fontSize: 9)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(difficulty ?? 'سهل التلاوة', style: GoogleFonts.cairo(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Grammatical annotations list
                if (notes.isNotEmpty) ...[
                  Text('📚 التفصيل التوضيحي والقواعد النحوية المطبقة:', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notes.length,
                    itemBuilder: (ctx, idx) {
                      final note = notes[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF042D24),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF073D30)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                              radius: 12,
                              child: Text('${idx + 1}', style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: '${note['word']}  ⟵  ', style: GoogleFonts.cairo(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    TextSpan(text: note['rule'], style: GoogleFonts.cairo(color: Colors.grey[200], fontSize: 11)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  )
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }
}
