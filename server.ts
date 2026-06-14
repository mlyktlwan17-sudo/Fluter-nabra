import express from "express";
import path from "path";
import fs from "fs";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI, Type, Modality } from "@google/genai";
import dotenv from "dotenv";
import AdmZip from "adm-zip";
import { fileURLToPath } from "url";

dotenv.config();

let resolvedFilename = "";
let resolvedDirname = "";

try {
  resolvedFilename = __filename;
} catch (e) {}

try {
  resolvedDirname = __dirname;
} catch (e) {}

if (!resolvedFilename) {
  try {
    const metaUrl = typeof import.meta !== "undefined" && import.meta ? import.meta.url : undefined;
    if (metaUrl) {
      resolvedFilename = fileURLToPath(metaUrl);
    }
  } catch (e) {}
}

if (!resolvedDirname) {
  try {
    if (resolvedFilename) {
      resolvedDirname = path.dirname(resolvedFilename);
    } else {
      resolvedDirname = process.cwd();
    }
  } catch (e) {
    resolvedDirname = process.cwd();
  }
}

const __filename = resolvedFilename || "";
const __dirname = resolvedDirname;

const app = express();
const PORT = 3000;

app.use(express.json({ limit: "15mb" }));

// Initialize Gemini client strictly using the safe guidelines
const apiKey = process.env.GEMINI_API_KEY;
const ai = apiKey
  ? new GoogleGenAI({
      apiKey: apiKey,
      httpOptions: {
        headers: {
          "User-Agent": "aistudio-build",
        },
      },
    })
  : null;

// Helper to check if AI is available
function checkAi(res: express.Response): boolean {
  if (!ai) {
    res.status(500).json({
      error: "من فضلك قم بإعداد مفتاح API الخاص بـ Gemini في نافذة الأسرار (Secrets) لتفعيل الذكاء الاصطناعي.",
    });
    return false;
  }
  return true;
}

// النافذة الأولى: تشكيل النص العربي
app.post("/api/diacritize", async (req, res) => {
  if (!checkAi(res)) return;
  const { text } = req.body;
  if (!text || typeof text !== "string") {
    return res.status(400).json({ error: "النص مطلوب للتشكيل" });
  }

  try {
    const prompt = `أنت خبير لغوي من الطراز الأول متعمق في النحو والصرف الإعرابي وبلاغة اللسان العربي وتشكيله الفونولوجي.
مهمتك الحتمية هي تشكيل النص العربي التالي تشكيلاً كاملاً، دقيقاً، وصحيحاً من الناحية النحوية والصرفية بنسبة 100%.

قواعد بالغة الأهمية لتطبيقها:
1. تشكيل أواخر الكلمات (حركات الإعراب والبناء): يجب وضع الحركة الإعرابية الصحيحة على الحرف الأخير لكل كلمة بناءً على موقعها الإعرابي في الجملة (ضم، فتح، كسر، سكون، تنوين). لا تترك الحرف الأخير ساكناً أو بغير تشكيل إلا إذا كان ساكناً في اللغة.
2. ضبط البنية الصرفية الداخلية: اضبط وزن الكلمة بدقة بالغة (مثل الفتح والضم والكسر والتضعيف/الشدة).
3. الشدة وحركتها: تأكد من رسم الشدة فوق الحرف المضعف مع حركتها المرافقة (مثال: الشَّدَّةُ، المعَلِّمُ).
4. الإعجام وحروف المد: احرص على عدم الخلط بين الحركات الطويلة (حروف المد) والحركات القصيرة.
5. الدقة المطلقة: لا تحذف، ولا تبدل، ولا تغير أي حرف من النص الأصلي مطلقاً. فقط أضف التشكيل والضبط المناسب.

النص المراد تشكيله وضبطه:
"${text}"

أرجع النتيجة بصيغة JSON مطابقة تماماً للمخطط التالي منادياً لكل التفاصيل:
{
  "diacritizedText": "النص مع التشكيل الإعرابي والصرفي الكامل والدقيق للغاية لكل الحروف والكلمات بما فيها حركات الإعراب الأخيرة",
  "notes": [
    {
      "word": "الكلمة التي تم ضبطها",
      "rule": "التعليل النحوي أو الصرفي الدقيق لحركتها الإعرابية أو بنيتها الصرفية لمساعدة المستخدم في تحسين نطقه"
    }
  ],
  "difficulty": "مستوى القراءة الصوتي (سهل / متوسط / متقدم) مع تعليل نحوي وصوتي لغوي موجز"
}`;

    const response = await ai!.models.generateContent({
      model: "gemini-3.5-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            diacritizedText: { type: Type.STRING },
            notes: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  word: { type: Type.STRING },
                  rule: { type: Type.STRING },
                },
                required: ["word", "rule"],
              },
            },
            difficulty: { type: Type.STRING },
          },
          required: ["diacritizedText", "notes", "difficulty"],
        },
      },
    });

    const data = JSON.parse(response.text || "{}");
    res.json(data);
  } catch (error: any) {
    console.error("Error in diacritize endpoint:", error);
    res.status(500).json({ error: "فشل تشكيل النص تلقائياً: " + (error.message || error) });
  }
});

// النافذة الثانية: تحويل النص إلى كلام (TTS)
app.post("/api/generate-tts", async (req, res) => {
  if (!checkAi(res)) return;
  const { text } = req.body;
  if (!text || typeof text !== "string") {
    return res.status(400).json({ error: "النص مطلوب لتوليد الصوت" });
  }

  try {
    // Generate vocal speech with TTS model (gemini-3.1-flash-tts-preview)
    const response = await ai!.models.generateContent({
      model: "gemini-3.1-flash-tts-preview",
      contents: [{ parts: [{ text: `انطق العبارة التالية بلسان عربي مبين وفصيح بلهجة دقيقة ومخارج صحيحة: ${text}` }] }],
      config: {
        responseModalities: [Modality.AUDIO],
        speechConfig: {
          voiceConfig: {
            prebuiltVoiceConfig: { voiceName: "Kore" }, // Elegant, balanced warm voice
          },
        },
      },
    });

    const base64Audio = response.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
    if (base64Audio) {
      res.json({ audio: base64Audio });
    } else {
      res.status(500).json({ error: "لم يتم استخراج الصوت بتنسيق صحيح" });
    }
  } catch (error: any) {
    console.error("Error in generate-tts endpoint:", error);
    res.status(500).json({
      error: "فشل توليد الصوت عبر خادم الذكاء الاصطناعي المباشر. يرجى تفعيل مفتاح الدفع المسبق أو استخدام المحرك الصوتي الداخلي للمتصفح المرفق للتوليد الصوتي الفوري.",
      fallbackDeviceTTS: true,
    });
  }
});

// النافذة الثالثة والرابعة والخامسة: تقويم الأداء اللفظي ومخارج الحروف
app.post("/api/analyze-phonetics", async (req, res) => {
  if (!checkAi(res)) return;
  const { expectedText, userTranscription, activeLetter } = req.body;

  if (!expectedText || typeof expectedText !== "string") {
    return res.status(400).json({ error: "النص المتوقع مطلوب للتحليل" });
  }

  const userText = userTranscription || "";

  try {
    const prompt = `أنت خبير متميز في اللسانيات العامة، الصوتيات الفيزيولوجية العربية، الأرطفونيا (علاج اضطرابات النطق والكلام)، وعلم النفس اللغوي.
مهمتك هي إجراء تحليل مقارن عميق بين النطق المتوقع والنطق الفعلي للمستخدم للتعرف على عيوب النطق وتحديد مخارج وصفات الحرف المستهدف.

النص النموذجي (المتوقع): "${expectedText}"
النطق الفعلي للمستخدم (المكتوب): "${userText}"
${activeLetter ? `الحرف المستهدف بالتركيز والتدقيق: "${activeLetter}"` : ""}

الرجاء تحليل الأداء الصوتي للمستخدم ومقارنته بالنص المتوقع وتوليد استجابة بصيغة JSON مطابقة تماماً للمخطط المحدد.

مثال للمخطط المطلوب:
{
  "generalCorrectnessScore": 85,
  "vocalScores": {
    "articulation": 80,
    "vocalization": 90,
    "fluency": 85,
    "phonology": 85
  },
  "detectedErrors": [
    {
      "letter": "ر",
      "errorType": "لثغة أو تبديل الحرف",
      "description": "تم تبديل حرف الراء بياء أو لام في النطق الفعلي",
      "correctionTip": "ضع حافة اللسان الأمامية عند لثة الأسنان العليا الخلفية مع تكرار خفيف دون غلق تام للممر الهوائي."
    }
  ],
  "letterDetails": {
    "makhraj": "طرف اللسان مع ما بين الثنايا العليا والسفلى أو لثة الأسنان العليا",
    "sifat": "الجهر، التوسط، الاستفال، الانفتاح، الإذلاق، الانحراف، التكرير"
  },
  "remedialExercises": [
    {
      "exerciseName": "تمرين تثبيت حافة اللسان للاصطدام بلثة الثنايا العليا",
      "howToPerform": "قم بملء الفم بالهواء ووضع طرف اللسان في سقف الحلق وإصدار نغمة مستمرة لصوت الراء المكرر بشكل خفيف.",
      "repetition": "3 مرات يومياً لمدة 5 دقائق"
    }
  ],
  "advice": "نصائح عامة وتوجيه نفسي مهدئ لرفع الثقة بالنفس وتغذية الطمأنينة الصوتية"
}`;

    const response = await ai!.models.generateContent({
      model: "gemini-3.5-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            generalCorrectnessScore: { type: Type.INTEGER },
            vocalScores: {
              type: Type.OBJECT,
              properties: {
                articulation: { type: Type.INTEGER },
                vocalization: { type: Type.INTEGER },
                fluency: { type: Type.INTEGER },
                phonology: { type: Type.INTEGER },
              },
              required: ["articulation", "vocalization", "fluency", "phonology"],
            },
            detectedErrors: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  letter: { type: Type.STRING },
                  errorType: { type: Type.STRING },
                  description: { type: Type.STRING },
                  correctionTip: { type: Type.STRING },
                },
                required: ["letter", "errorType", "description", "correctionTip"],
              },
            },
            letterDetails: {
              type: Type.OBJECT,
              properties: {
                makhraj: { type: Type.STRING },
                sifat: { type: Type.STRING },
              },
              required: ["makhraj", "sifat"],
            },
            remedialExercises: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  exerciseName: { type: Type.STRING },
                  howToPerform: { type: Type.STRING },
                  repetition: { type: Type.STRING },
                },
                required: ["exerciseName", "howToPerform", "repetition"],
              },
            },
            advice: { type: Type.STRING },
          },
          required: [
            "generalCorrectnessScore",
            "vocalScores",
            "detectedErrors",
            "letterDetails",
            "remedialExercises",
            "advice",
          ],
        },
      },
    });

    const data = JSON.parse(response.text || "{}");
    res.json(data);
  } catch (error: any) {
    console.error("Error in analyze-phonetics:", error);
    res.status(500).json({ error: "فشل تحليل الأداء النطقي: " + (error.message || error) });
  }
});

// العيادة الاستعجالية الرقمية المشتركة بين خبير اللسانيات، الأرطوفونيا، وعلم النفس
app.post("/api/clinic-consultation", async (req, res) => {
  if (!checkAi(res)) return;
  const { ageGroup, primaryIssue, patientStory, severity } = req.body;

  try {
    const prompt = `أنت تمثل الهيئة الطبية الاستشارية لـ "العيادة الاستعجالية الرقمية للأداء الصوتي" المكونة من ثلاثة خبراء متميزين يعملون يداً بيد:
1. البروفيسور الخبير اللساني (مختص أصوات ومخارج لغوية وقراءات مخبرية)
2. المعالج الأرطوفوني (أخصائي اضطرابات النطق وعلاج مخارج الحروف)
3. المعالج النفسي اللغوي (أخصائي الخوف الاجتماعي، الطمأنينة الصوتية وبناء الثقة بالنفس والارتياح اللفظي)

بيانات المريض الحالي:
- الفئة العمرية: ${ageGroup}
- المشكلة الأساسية: ${primaryIssue}
- قصة الحالة بالتفصيل: ${patientStory}
- شدة الحالة المقدرة: ${severity}

قم بصياغة تقرير عيادي طبي استشاري لغوي متكامل ونموذجي ومنظم باللغة العربية الفصحى.`;

    const response = await ai!.models.generateContent({
      model: "gemini-3.5-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            diagnosticSummary: { type: Type.STRING, description: "ملخص التشخيص الموحد المتكامل للحالة باللغة العربية." },
            linguisticExpertReview: { type: Type.STRING, description: "رأي وتحليل الخبير اللساني لمخارج الحروف ونبرة الصوت بدقة." },
            speechTherapistReview: { type: Type.STRING, description: "توصيات المعالج الأرطوفوني لتمارين مخارج الحروف وعلاج الاضطرابات." },
            psychologistReview: { type: Type.STRING, description: "رأي الخبير النفسي اللغوي لبناء الثقة وتقليل رهبة الحديث النفسية." },
            weeksPlan: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  weekNum: { type: Type.STRING, description: "الأسبوع المستهدف مثلا: الأسبوع الأول والثاني" },
                  goal: { type: Type.STRING, description: "الهدف العلاجي المخصص" },
                  activities: { type: Type.STRING, description: "الأنشطة المحددة والتمارين المطلوبة بدقة" }
                },
                required: ["weekNum", "goal", "activities"]
              }
            },
            prognosisAndStatus: { type: Type.STRING, description: "التوقعات الطبية ونسبة الشفاء التقديرية بالالتزام." }
          },
          required: [
            "diagnosticSummary",
            "linguisticExpertReview",
            "speechTherapistReview",
            "psychologistReview",
            "weeksPlan",
            "prognosisAndStatus"
          ]
        }
      }
    });

    const report = JSON.parse(response.text || "{}");
    res.json(report);
  } catch (error: any) {
    console.error("Error in clinic-consultation:", error);
    res.status(500).json({ error: "فشل استشارة العيادة الرقمية: " + (error.message || error) });
  }
});

const handleApkInstructions = (req: express.Request, res: express.Response) => {
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  const downloadUrl = `${req.protocol}://${req.get('host')}/nabra_flutter_app.zip`;
  res.send(`
    <!DOCTYPE html>
    <html lang="ar" dir="rtl">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>تطبيق نبرة AI للهواتف</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;900&display=swap" rel="stylesheet">
      <style>
        body {
          font-family: 'Cairo', sans-serif;
        }
      </style>
    </head>
    <body class="bg-[#021410] text-slate-100 min-h-screen flex items-center justify-center p-4">
      <div class="max-w-xl w-full bg-[#FAF9F5] text-slate-800 rounded-3xl overflow-hidden shadow-2xl border-2 border-[#ebd382]/30 animate-in fade-in zoom-in duration-200">
        <!-- Logo Header -->
        <div class="bg-gradient-to-b from-[#063C2E] to-[#04281E] p-8 text-center text-white relative">
          <div class="text-[#ebd382] text-5xl mb-3">📱</div>
          <h1 class="text-2xl font-black text-[#ebd382]">تطبيق نبرة AI للهواتف المحمولة</h1>
          <p class="text-xs text-slate-300 mt-2">الملف المصدري الكامل وحل التثبيت الفوري</p>
        </div>

        <!-- Details -->
        <div class="p-6 sm:p-8 space-y-6 text-right">
          
          <div class="bg-amber-500/10 border border-amber-500/20 text-amber-900 rounded-2xl p-4 text-xs leading-relaxed space-y-2">
            <p class="font-bold flex items-center gap-1.5">
              <span>💡</span> معذرة وتوضيح تقني هام جداً:
            </p>
            <p class="text-[11px] leading-relaxed">
              لتصنيع ملف تثبيت <strong>APK</strong> حقيقي لتطبيق هاتف من لغة Flutter، نحتاج تكنولوجياً لتشغيل محركات وأدوات ثقيلة جداً تسمى (Android SDK & Gradle) والتي تفوق 10 جيجابايت لتجميع الكود. هذه الأدوات غير متوفرة إطلاقاً في السيرفرات السحابية الويب المخصصة للمواقع والذكاء الاصطناعي، وبالتالي لا يُمكننا المولد التلقائي لملف <strong>.apk</strong> جاهز داخل الخادم.
            </p>
          </div>

          <!-- PWA Native Alternative (The Absolute Best and easiest solution) -->
          <div class="border-2 border-emerald-600/20 bg-emerald-50/30 rounded-2xl p-5 space-y-3">
            <span class="bg-emerald-600 text-white text-[11px] font-black px-2.5 py-1 rounded-full uppercase">
              ⚡ الحل البديل الأسرع والأذكى دون أي تحميل:
            </span>
            <h3 class="text-base font-bold text-emerald-950">تثبيت فوري كأيقونة تطبيق كاملة بالهاتف (PWA)</h3>
            <p class="text-xs text-slate-650 leading-relaxed">
              افتح رابط المنصة الرئيسي من تليفونك عبر متصفح <strong>جوجل كروم (Chrome)</strong> للأندرويد، أو متصفح <strong>سفاري (Safari)</strong> للآيفون، ثم اضغط على زر <strong>القائمة (النقاط الثلاث)</strong> في كروم أو زر <strong>المشاركة</strong> في سفاري واضغط على: <strong>"إضافة إلى الشاشة الرئيسية"</strong>.
            </p>
            <p class="text-xs text-slate-650 leading-relaxed font-bold text-emerald-900">
              سيظهر لك التطبيق بأيقونته الجميلة "نبرة" على واجهة شاشة هاتفك مباشرة، وسيعمل بشاشة كاملة كأنك قمت بتنزيل ملف APK تماماً وبنعومة مطلقة!
            </p>
          </div>

          <!-- ZIP Source Code Download -->
          <div class="bg-emerald-900 text-white rounded-2xl p-6 text-center space-y-4 shadow-lg border border-[#ebd382]/35">
            <h3 class="text-lg font-bold text-[#ebd382] flex items-center justify-center gap-2">
              <span>📦</span> تحميل الكود البرمجي الكامل للفلاتر (ZIP)
            </h3>
            <p class="text-xs text-slate-200 leading-normal">
              لقد وضعنا لك شفرة التطبيق بالكامل في مجلد مضغوط. يمكنك تحميله بضغطة واحدة وإرساله لأي مبرمج أو فتحه في حاسوبك لتصديره كملف APK في دقيقة:
            </p>
            
            <div class="space-y-3">
              <!-- Direct JS Blob Download Button -->
              <button 
                id="btn-direct-download"
                onclick="triggerSecureDownload()" 
                class="inline-flex justify-center items-center gap-2 w-full bg-[#ebd382] hover:bg-[#ebd382]/90 text-emerald-950 font-black text-sm py-3 px-6 rounded-xl transition-all shadow-md transform active:scale-95 text-center cursor-pointer"
              >
                📥 تحميل الكود المصدري كاملاً (ZIP)
              </button>

              <!-- Link display -->
              <div id="link-display-container" class="hidden text-right bg-slate-950/40 p-2.5 rounded-lg border border-white/5 space-y-1">
                <span class="text-[10px] text-[#ebd382] block font-bold">الرابط المباشر للملَف:</span>
                <input 
                  type="text" 
                  id="direct-url-input" 
                  readonly 
                  class="w-full bg-transparent text-slate-300 text-xs font-mono p-1 select-all focus:outline-none text-center border-none"
                />
              </div>

              <!-- Success Alert -->
              <div id="notice-box" class="hidden text-xs rounded-xl bg-teal-950/40 border border-teal-500/30 p-3 text-[#ebd382] leading-normal text-right">
                ✨ تم نسخ الرابط المباشر بنجاح! من فضلك افتح متصفحك في علامة تبويب جديدة تماماً والصق الرابط وسيتم التحميل فوراً ودون أي قيود.
              </div>
            </div>
          </div>

          <div class="border-t border-slate-100 pt-4 flex justify-between items-center">
            <a href="/" class="text-emerald-900 font-bold text-xs hover:underline">العودة للرئيسية ←</a>
            <span class="text-[10px] text-slate-400">منصة نبرة AI للتقويم الصوتي اللغوي</span>
          </div>
        </div>
      </div>

      <!-- Advanced Client-Side Download Script -->
      <script>
        document.addEventListener("DOMContentLoaded", function() {
          const currentOrigin = window.location.origin;
          const fullZipUrl = currentOrigin + "/nabra_flutter_app.zip";
          
          document.getElementById("direct-url-input").value = fullZipUrl;
          document.getElementById("link-display-container").classList.remove("hidden");
        });

        async function triggerSecureDownload() {
          const btn = document.getElementById("btn-direct-download");
          const originalText = btn.innerText;
          btn.innerText = "⏳ جاري تحميل مجلد الكود ZIP المصدري...";
          btn.disabled = true;

          const currentOrigin = window.location.origin;
          const fullZipUrl = currentOrigin + "/nabra_flutter_app.zip";

          try {
            const response = await fetch(fullZipUrl);
            if (!response.ok) throw new Error("فشل في أداء تحميل الملف من الاستضافة.");
            
            const blob = await response.blob();
            const downloadUrl = URL.createObjectURL(blob);
            
            const link = document.createElement("a");
            link.href = downloadUrl;
            link.download = "nabra_flutter_app.zip";
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(downloadUrl);
            
            btn.innerText = "✅ اكتمل التحميل!";
          } catch (err) {
            console.error(err);
            btn.innerText = "⚠️ فشل التحميل المباشر";
            
            // Auto copy fallback
            const urlInput = document.getElementById("direct-url-input");
            urlInput.select();
            urlInput.setSelectionRange(0, 99999);
            navigator.clipboard.writeText(urlInput.value);

            document.getElementById("notice-box").classList.remove("hidden");
            alert("تمنع منصة قوقل التنزيلات المباشرة أحياناً لأسباب أمنية. لقد قمنا بنسخ الرابط المباشر بنجاح! يرجى لصقه يدوياً في صفحة أو علامة تبويب جديدة وسيبدأ تنزيل كود فلاتر فوراً!");
          } finally {
            setTimeout(() => {
              btn.innerText = originalText;
              btn.disabled = false;
            }, 5000);
          }
        }
      </script>
    </body>
    </html>
  `);
};

// Endpoint to dynamically ZIP the flutter_app directory on request
app.get(["/nabra_flutter_app.zip", "/app.zip", "/flutter-source.zip", "/download-zip"], (req, res) => {
  try {
    const zip = new AdmZip();
    const pathsToTry = [
      path.join(process.cwd(), "flutter_app"),
      path.join(__dirname, "flutter_app"),
      path.join(__dirname, "..", "flutter_app"),
      "/flutter_app",
      "/applet/flutter_app"
    ];
    
    let flutterAppPath = "";
    for (const p of pathsToTry) {
      if (fs.existsSync(p)) {
        flutterAppPath = p;
        break;
      }
    }
    
    if (flutterAppPath) {
      console.log("[Zip Route] Creating live dynamic zip from:", flutterAppPath);
      zip.addLocalFolder(flutterAppPath);
      const zipBuffer = zip.toBuffer();
      
      res.setHeader("Content-Type", "application/zip");
      res.setHeader("Content-Disposition", 'attachment; filename="nabra_flutter_app.zip"');
      res.send(zipBuffer);
    } else {
      res.status(404).send("مجلد تطبيق Flutter غير موجود حالياً في بيئة العمل السحابية. الرجاء التأكد من وجود مجلد flutter_app.");
    }
  } catch (error: any) {
    console.error("Error creating ZIP download dynamically:", error);
    res.status(500).send("حدث خطأ أثناء تجميع ملفات تطبيق الجوال: " + error.message);
  }
});

app.get("/app.apk", handleApkInstructions);
app.get("/nabra.apk", handleApkInstructions);
app.get("/app-release.apk", handleApkInstructions);
app.get("/flutter.apk", handleApkInstructions);
app.get("/download-apk", handleApkInstructions);
app.get("/apk", handleApkInstructions);

// Setup Vite Dev Server / Serve Static Files
async function startServer() {
  // Determine if we are running in production mode (production bundle server.cjs)
  let isProduction = process.env.NODE_ENV === "production";

  // Override: If running using tsx or server.ts, force development mode
  const isDevProcess = process.argv.some(arg => 
    arg.includes("server.ts") || 
    arg.includes("tsx") || 
    arg.includes("node_modules/tsx")
  );

  if (isDevProcess) {
    isProduction = false;
  }

  // Pre-generate the physical ZIP file inside public/ and dist/
  try {
    const zip = new AdmZip();
    const pathsToTry = [
      path.join(process.cwd(), "flutter_app"),
      path.join(__dirname, "flutter_app"),
      path.join(__dirname, "..", "flutter_app"),
      "/flutter_app",
      "/applet/flutter_app"
    ];
    
    let flutterAppPath = "";
    for (const p of pathsToTry) {
      if (fs.existsSync(p)) {
        flutterAppPath = p;
        break;
      }
    }

    if (flutterAppPath) {
      zip.addLocalFolder(flutterAppPath);
      
      const publicPath = path.join(process.cwd(), "public");
      if (!fs.existsSync(publicPath)) {
        fs.mkdirSync(publicPath, { recursive: true });
      }
      zip.writeZip(path.join(publicPath, "nabra_flutter_app.zip"));
      console.log("[Zip Generator] Created public/nabra_flutter_app.zip on startup.");

      const distPath = path.join(process.cwd(), "dist");
      if (fs.existsSync(distPath)) {
        zip.writeZip(path.join(distPath, "nabra_flutter_app.zip"));
        console.log("[Zip Generator] Created dist/nabra_flutter_app.zip on startup.");
      }
    } else {
      console.warn("[Zip Generator] Warning: flutter_app directory not found in paths:", pathsToTry);
    }
  } catch (err) {
    console.error("[Zip Generator] Error pre-generating ZIP file:", err);
  }

  const distPath = path.join(process.cwd(), "dist");
  const hasDist = fs.existsSync(distPath);

  // Fallback: If we think we're in production but there is no build directory, fallback to avoid "Not Found"
  if (isProduction && !hasDist) {
    console.warn("[Vite Host Server] Warning: Production mode was requested but 'dist/' directory does not exist. Falling back to development Vite middleware...");
    isProduction = false;
  }

  if (!isProduction) {
    console.log("[Vite Host Server] Starting in DEVELOPMENT mode using Vite middleware...");
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    console.log("[Vite Host Server] Starting in PRODUCTION mode serving static files...");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`[Vite Host Server] Server running on http://localhost:${PORT}`);
  });
}

startServer();
