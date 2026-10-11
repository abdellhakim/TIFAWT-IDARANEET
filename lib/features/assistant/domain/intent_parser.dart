import '../../../shared/models/profile_enums.dart';

enum AssistantIntent {
  greeting,
  thanks,
  lost,
  lowConfidence,
  counselor,
  searchTraining,
  searchJob,
  searchInternship,
  entrepreneurship,
  support,
  studies,
  centers,
  progress,
  recommend,
  explore,
  faq,
  unknown,
}

/// What the assistant understood from one message.
class Understanding {
  const Understanding({
    required this.intent,
    required this.isAr,
    this.domain,
    this.nearOnly = false,
    this.freeOnly = false,
    this.women = false,
    this.faqId,
  });

  final AssistantIntent intent;

  /// Language of the reply: detected from the message, not the interface.
  final bool isAr;
  final Interest? domain;
  final bool nearOnly;
  final bool freeOnly;
  final bool women;
  final String? faqId;
}

/// Keyword-based intent detection over normalised text. Handles Arabic
/// script, Darija written in Latin letters ("bghit khdma") and French.
class IntentParser {
  IntentParser({Map<String, List<String>> faqKeywords = const {}})
    : _faq = {
        for (final MapEntry(:key, :value) in faqKeywords.entries) key: [for (final k in value) normalize(k)],
      };

  final Map<String, List<String>> _faq;

  static final _arabicLetters = RegExp('[؀-ۿ]');

  static String normalize(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp('[ً-ٰٟـ]'), '');
    const map = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ٱ': 'ا',
      'ة': 'ه',
      'ى': 'ي',
      'ؤ': 'و',
      'ئ': 'ي',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'à': 'a',
      'â': 'a',
      'ç': 'c',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'û': 'u',
      'ù': 'u',
      '’': "'",
    };
    final buffer = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(map[ch] ?? ch);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r"[?!.,;:'«»()\-]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _arabiziMarkers = {
    'bghit',
    'bgheet',
    'chi',
    'wach',
    'wash',
    'khdma',
    'khedma',
    'kifach',
    'kifash',
    'dyal',
    'dial',
    'bzaf',
    'nta',
    'nti',
    'wakha',
    'labas',
    'nkhdem',
    'nt3alm',
    'ma3reftch',
    'mafhemtch',
    'chokran',
    'choukran',
    '3afak',
    'mzyan',
  };
  static const _frenchMarkers = {
    'je',
    'j',
    'une',
    'un',
    'des',
    'les',
    'cherche',
    'formation',
    'travail',
    'emploi',
    'bonjour',
    'merci',
    'pour',
    'mais',
    'pas',
    'est',
    'comment',
    'ou',
    'mon',
    'ma',
    'suis',
    'veux',
    'voudrais',
    'quoi',
    'quel',
    'quelle',
    'avec',
    'dans',
  };

  static bool detectArabic(String text, {required bool fallback}) {
    if (_arabicLetters.hasMatch(text)) return true;
    final words = normalize(text).split(' ').toSet();
    if (words.intersection(_arabiziMarkers).isNotEmpty) return true;
    if (words.intersection(_frenchMarkers).isNotEmpty) return false;
    return fallback;
  }

  // Keyword lists are written naturally and normalised on use.
  static const _kw = <AssistantIntent, List<String>>{
    AssistantIntent.greeting: [
      'bonjour',
      'bonsoir',
      'salut',
      'salam',
      'السلام',
      'سلام',
      'اهلا',
      'مرحبا',
      'صباح الخير',
      'مساء الخير',
      'hello',
      'labas',
      'لاباس',
    ],
    AssistantIntent.thanks: [
      'merci',
      'شكرا',
      'الله يخليك',
      'بارك الله',
      'تبارك الله',
      'choukran',
      'chokran',
      'tbarkellah',
    ],
    AssistantIntent.lost: [
      'perdu',
      'je sais pas',
      'je ne sais pas',
      'aucune idee',
      'ضايع',
      'حاير',
      'ماكنقراش',
      'ما كنقراش',
      'ماخدامش',
      'ما خدامش',
      'مخدامش',
      'ma3reftch',
    ],
    AssistantIntent.lowConfidence: [
      'confiance',
      'decourage',
      'triste',
      'marre',
      'fatigue de',
      'الثقة',
      'عييت',
      'يائس',
      'حزين',
      'مقلق',
      'ما عرفتش',
      'ماعرفتش',
    ],
    AssistantIntent.counselor: ['parler a quelqu', 'conseiller', 'quelqu un', 'نهضر مع', 'مستشار', 'شي حد'],
    AssistantIntent.searchInternship: ['stage', 'stagiaire', 'تدريب', 'ستاج', 'stage pratique'],
    AssistantIntent.searchJob: [
      'emploi',
      'travail',
      'boulot',
      'job',
      'embauche',
      'poste',
      'travailler',
      'خدمة',
      'نخدم',
      'شغل',
      'khdma',
      'khedma',
      'nkhdem',
      'awrach',
      'اوراش',
    ],
    AssistantIntent.entrepreneurship: [
      'projet',
      'entreprise',
      'creer mon',
      'cooperative',
      'auto entrepreneur',
      'mon activite',
      'مشروع',
      'مقاولة',
      'تعاونية',
      'نبدا',
      'machrou3',
    ],
    AssistantIntent.searchTraining: [
      'formation',
      'former',
      'apprendre',
      'cours',
      'atelier',
      'تكوين',
      'نتكون',
      'نتعلم',
      'تعلم',
      'دروس',
      'ورشة',
      'takwin',
      'nt3alm',
      'ntkwen',
    ],
    AssistantIntent.studies: [
      'etudes',
      'ecole',
      'lycee',
      'reprendre mes',
      'القراية',
      'نقرا',
      'المدرسة',
      'نكمل قرايتي',
      'alphabetisation',
      'الامية',
    ],
    AssistantIntent.support: [
      'aides',
      'financement',
      'bourse',
      'subvention',
      'dispositif',
      'دعم',
      'تمويل',
      'منحة',
      'برامج الدعم',
    ],
    AssistantIntent.centers: [
      'centre',
      'centres',
      'maison de jeunes',
      'association',
      'agence',
      'adresse',
      'مركز',
      'المراكز',
      'دار الشباب',
      'جمعية',
      'وكالة',
      'منصة الشباب',
    ],
    AssistantIntent.progress: [
      'parcours',
      'progression',
      'etape',
      'avancement',
      'المسار',
      'مسار',
      'التقدم',
      'المرحلة',
    ],
    AssistantIntent.recommend: [
      'recommand',
      'conseill',
      'propose',
      'quoi faire',
      'que faire',
      'شنو ندير',
      'نصيحة',
      'اقتراح',
      'توصي',
      'شنو تنصحني',
    ],
  };

  static const _domains = <Interest, List<String>>{
    Interest.care: [
      'aide a la personne',
      'auxiliaire',
      'soins',
      'personnes agees',
      'رعاية',
      'العناية',
      'كبار السن',
      'تمريض',
    ],
    Interest.digital: [
      'informatique',
      'numerique',
      'ordinateur',
      'ordi',
      'pc',
      'internet',
      'digital',
      'bureautique',
      'programmation',
      'حاسوب',
      'معلوميات',
      'المعلوميات',
      'رقمي',
      'الرقميات',
      'انفورماتيك',
      'لانفورماتيك',
      'informatik',
    ],
    Interest.agriculture: [
      'agriculture',
      'agricole',
      'exploitation',
      'elevage',
      'safran',
      'irrigation',
      'فلاحة',
      'الفلاحة',
      'زراعة',
      'الزعفران',
      'fla7a',
    ],
    Interest.tourism: [
      'tourisme',
      'hotel',
      'hotellerie',
      'guide',
      'reception',
      'سياحة',
      'السياحة',
      'فندق',
      'الفندقة',
    ],
    Interest.commerce: [
      'commerce',
      'vente',
      'vendre',
      'magasin',
      'boutique',
      'تجارة',
      'التجارة',
      'بيع',
      'حانوت',
    ],
    Interest.marketing: [
      'marketing',
      'reseaux sociaux',
      'facebook',
      'publicite',
      'تسويق',
      'التسويق',
      'ماركتينغ',
    ],
    Interest.crafts: [
      'artisanat',
      'couture',
      'broderie',
      'tapis',
      'electricite',
      'electricien',
      'plomberie',
      'menuiserie',
      'حرفة',
      'الصناعة التقليدية',
      'خياطة',
      'الخياطة',
      'طرز',
      'زرابي',
      'الكهرباء',
      'سباكة',
    ],
    Interest.renewableEnergy: ['solaire', 'energie', 'panneaux', 'renouvelable', 'طاقة', 'الطاقة', 'شمسية'],
    Interest.logistics: ['logistique', 'livraison', 'chauffeur', 'entrepot', 'لوجستيك', 'التوصيل'],
    Interest.foodProcessing: [
      'cuisine',
      'patisserie',
      'argan',
      'huile',
      'alimentaire',
      'طبخ',
      'الطبخ',
      'حلويات',
      'الحلويات',
      'اركان',
      'زيت',
    ],
  };

  static const _near = [
    'deplacer',
    'deplacement',
    'transport',
    'loin',
    'pres de',
    'proche',
    'pas de voiture',
    'a cote',
    'قريب',
    'بعيد',
    'نتنقل',
    'التنقل',
    'الطوبيس',
    'الكار',
    'qrib',
    'b3id',
  ];
  static const _free = [
    'gratuit',
    'gratuite',
    'pas d argent',
    'sans payer',
    'مجاني',
    'مجانية',
    'فابور',
    'بلا فلوس',
    'ماعنديش الفلوس',
    'ما عنديش الفلوس',
  ];
  static const _women = ['pour les femmes', 'femme', 'fille', 'للنساء', 'نساء', 'المراه', 'بنت'];

  static final _wordCache = <String, RegExp>{};

  static bool _has(String text, List<String> keywords) {
    for (final k in keywords) {
      final nk = normalize(k);
      if (nk.isEmpty) continue;
      // Short Latin keywords match whole words only (plural allowed), so
      // "cours" does not fire on "parcours" nor "pc" inside another word.
      if (nk.length <= 5 && !_arabicLetters.hasMatch(nk)) {
        final re = _wordCache.putIfAbsent(nk, () => RegExp('(^| )${RegExp.escape(nk)}s?( |\$)'));
        if (re.hasMatch(text)) return true;
      } else if (text.contains(nk)) {
        return true;
      }
    }
    return false;
  }

  static const _priority = [
    AssistantIntent.lowConfidence,
    AssistantIntent.lost,
    AssistantIntent.counselor,
    AssistantIntent.searchInternship,
    AssistantIntent.entrepreneurship,
    AssistantIntent.searchTraining,
    AssistantIntent.searchJob,
    AssistantIntent.studies,
    AssistantIntent.support,
    AssistantIntent.centers,
    AssistantIntent.progress,
    AssistantIntent.recommend,
  ];

  Understanding parse(String message, {required bool interfaceIsAr}) {
    final text = normalize(message);
    final isAr = detectArabic(message, fallback: interfaceIsAr);

    Interest? domain;
    for (final MapEntry(:key, :value) in _domains.entries) {
      if (_has(text, value)) {
        domain = key;
        break;
      }
    }

    String? faqId;
    for (final MapEntry(:key, :value) in _faq.entries) {
      if (_has(text, value)) {
        faqId = key;
        break;
      }
    }

    AssistantIntent? intent;
    for (final candidate in _priority) {
      if (_has(text, _kw[candidate]!)) {
        intent = candidate;
        break;
      }
    }

    // Practical questions always go to the FAQ; a programme name does too,
    // unless the message is a precise search ("formation OFPPT en informatique").
    if (faqId != null) {
      const practical = {'documents', 'cv', 'offline', 'privacy'};
      final genericSearch =
          domain == null && (intent == AssistantIntent.searchJob || intent == AssistantIntent.searchTraining);
      final toFaq =
          practical.contains(faqId) ||
          intent == null ||
          (faqId != 'free' &&
              (genericSearch || intent == AssistantIntent.support || intent == AssistantIntent.centers));
      if (toFaq) intent = AssistantIntent.faq;
    }

    intent ??= domain != null
        ? AssistantIntent.explore
        : _has(text, _kw[AssistantIntent.thanks]!)
        ? AssistantIntent.thanks
        : _has(text, _kw[AssistantIntent.greeting]!)
        ? AssistantIntent.greeting
        : AssistantIntent.unknown;

    return Understanding(
      intent: intent,
      isAr: isAr,
      domain: domain,
      nearOnly: _has(text, _near),
      freeOnly: _has(text, _free),
      women: _has(text, _women),
      faqId: faqId,
    );
  }
}
