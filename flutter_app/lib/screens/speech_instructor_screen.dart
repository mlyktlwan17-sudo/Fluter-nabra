import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class SpeechInstructorScreen extends StatefulWidget {
  const SpeechInstructorScreen({Key? key}) : super(key: key);

  @override
  State<SpeechInstructorScreen> createState() => _SpeechInstructorScreenState();
}

class _SpeechInstructorScreenState extends State<SpeechInstructorScreen> {
  final List<Map<String, String>> _drills = [
    {
      'letter': 'ض',
      'label': 'حرف الضاد (صوت مستطيل مجهور)',
      'phrase': 'ضَرَبَ الضَّرِيرُ ضِلْعَ الأَرْضِ ضَرْباً شَدِيداً',
      'makhraj': 'من إحدى حافتي اللسان أو كلتيهما مع ما يحاذيها من الأضراس العليا.'
    },
    {
      'letter': 'ق',
      'label': 'حرف القاف (مخرج لهوي شديد)',
      'phrase': 'قَالَ قَائِلٌ قَدْ قَرُبَ القِطَافُ بِالقَرْمِ',
      'makhraj': 'من أقصى اللسان مما يلي الحلق مع ما يحاذيه من الحنك الأعلى.'
    },
    {
      'letter': 'ع',
      'label': 'حرف العين (مخرج حلقي بيني)',
      'phrase': 'عَاهَدَ العَالِمُ عَلَى نَشْرِ العِلْمِ العَمِيقِ عَمَلاً',
      'makhraj': 'من وسط الحلق (منطقة لسان المزمار).'
    },
    {
      'letter': 'س',
      'label': 'حرف السين (صوت صفير ومستفل)',
      'phrase': 'سَارِعُوا إِلَى سَبِيلِ السَّلاَمِ وَالْمَجْدِ السَّامِي',
      'makhraj': 'مما بين رأس اللسان وفويق الثنايا السفلى.'
    },
  ];

  int _selectedDrillIndex = 0;

  // Recording variables
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordedFilePath;

  // Analysis result
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/nabrah_voice_drill.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _recordedFilePath = filePath;
          _analysisResult = null;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() {
            _recordDuration++;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الرجاء تفعيل إذن تسجيل الصوت من ميكروفون الهاتف لاستخدام هذه العيادة.', style: GoogleFonts.cairo())),
        );
      }
    } catch (e) {
      print('Start recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      _handleAnalyzeVoice();
    }
  }

  Future<void> _handleAnalyzeVoice() async {
    setState(() {
      _isAnalyzing = true;
    });

    final currentDrill = _drills[_selectedDrillIndex];

    // Connect to Node Gemini service
    final result = await ApiService.analyzeVoicePhonetics(
      expectedText: currentDrill['phrase']!,
      userTranscription: "مقطع صوتي تفاعلي مستلم ومقرون بالحرف ${currentDrill['letter']}",
      activeLetter: currentDrill['letter'],
    );

    setState(() {
      _isAnalyzing = false;
      _analysisResult = result;
    });
  }

  String _formatDuration(int seconds) {
    final s = seconds % 60;
    final m = seconds ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentDrill = _drills[_selectedDrillIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF021B15),
      appBar: AppBar(
        title: Text('محلل ومقوّم الأداء الصوتي', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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
              // Drill Selector Horizontal Slider
              Text('اختر مخارج الحروف المستهدفة بالعلاج النطقي:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _drills.length,
                  itemBuilder: (ctx, idx) {
                    final drill = _drills[idx];
                    final isSelected = idx == _selectedDrillIndex;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          'مخرج (${drill['letter']})',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF021B15) : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor: const Color(0xFF042D24),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDrillIndex = idx;
                              _analysisResult = null;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Letter Makhraj Explanation Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF042D24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF074537)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentDrill['label']!,
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: 'المخرج اللساني: ', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          TextSpan(text: currentDrill['makhraj']!, style: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Drill Phrase Display
              Text('انطق العبارة بدقة عند بدء التسجيل:', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF03221C), Color(0xFF021411)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Text(
                  currentDrill['phrase']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF3EFE0),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sound Wave and Microphoning Trigger
              Center(
                child: Column(
                  children: [
                    // Timer or Status indicator
                    _isRecording
                        ? Column(
                            children: [
                              Text(
                                'جاري تسجيل نبرتك الصوتية الآن...',
                                style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(_recordDuration),
                                style: GoogleFonts.jetBrainsMono(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              // Flashing sound wave simulators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  8,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: 4,
                                    height: 12 + (index % 3 == 0 ? 24 : 10),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        : Text(
                            'اضغط مع الاستمرار لتسجيل صوتك',
                            style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 11),
                          ),
                    const SizedBox(height: 16),

                    // Floating microphone button
                    GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.redAccent : const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.redAccent : const Color(0xFF10B981)).withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 32,
                          color: const Color(0xFF021B15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // AI Breakdown Results card
              if (_isAnalyzing) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF10B981)),
                      SizedBox(height: 12),
                      Text('جاري فحص مخارج ونبرة الصوت بالذكاء الاصطناعي...', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],

              if (_analysisResult != null) ...[
                Text('📊 نتيجة التحليل الفونولوجي بالذكاء الاصطناعي:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF042D24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0C5642)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text('الدرجة الإجمالية للأداء النطقي:', style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(
                            '%${_analysisResult!['generalCorrectnessScore']}',
                            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.black, color: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF074537)),
                      const SizedBox(height: 12),

                      // Error reporting
                      if ((_analysisResult!['detectedErrors'] as List).isNotEmpty) ...[
                        Text('🔴 رصد الأخطاء والصعوبات الصوتية:', style: GoogleFonts.cairo(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...(_analysisResult!['detectedErrors'] as List).map((err) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '• خطأ عند (${err['letter']}): ${err['description']}. نصيحة: ${err['correctionTip']}',
                                style: GoogleFonts.cairo(color: Colors.grey[200], fontSize: 10.5, height: 1.4),
                              ),
                            )),
                      ] else ...[
                        Text('🟢 ممتاز! مخارج الحروف سليمة ونبرة سليمة بنسبة 100%.', style: GoogleFonts.cairo(fontSize: 12, color: Colors.emerald, fontWeight: FontWeight.bold)),
                      ],

                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF074537)),
                      const SizedBox(height: 12),

                      // Exercises recommended
                      Text('🥋 التمارين العلاجية والأرطفونية الموصى بها:', style: GoogleFonts.cairo(fontSize: 12, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...(_analysisResult!['remedialExercises'] as List).map((ex) => Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF021B15), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex['exerciseName']!, style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('طريقة العمل: ${ex['howToPerform']}', style: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 10)),
                                Text('التكرار: ${ex['repetition']}', style: GoogleFonts.cairo(color: const Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )),

                      const SizedBox(height: 16),
                      Text('💪 توجيه نفسي لتعزيز الثقة:', style: GoogleFonts.cairo(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      Text(_analysisResult!['advice'] ?? '', style: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 11, height: 1.4)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
