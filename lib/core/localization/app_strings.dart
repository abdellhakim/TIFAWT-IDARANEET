import '../../shared/models/localized_text.dart';
import '../../shared/models/profile_enums.dart';
import 'app_language.dart';

/// Every piece of interface copy, in Darija (Arabic script) and French.
///
/// Kept in code rather than ARB files so the whole app switches language
/// instantly, offline, and so copy can take parameters (gender, counts).
class AppStrings {
  const AppStrings(this.language);
  final AppLanguage language;

  bool get isAr => language == AppLanguage.arabic;
  String t(String ar, String fr) => isAr ? ar : fr;
  String l(LocalizedText text) => text.of(isAr);
  String g(
    bool female, {
    required String arF,
    required String arM,
    required String frF,
    required String frM,
  }) => isAr ? (female ? arF : arM) : (female ? frF : frM);

  // ── General ───────────────────────────────────────────────────────────
  String get tagline => t('بوابتك نحو الفرص', 'Votre passerelle vers les opportunités');
  String get next => t('التالي', 'Suivant');
  String get back => t('رجوع', 'Retour');
  String get cancel => t('إلغاء', 'Annuler');
  String get confirm => t('تأكيد', 'Confirmer');
  String get close => t('سد', 'Fermer');
  String get seeMore => t('رؤية المزيد', 'Voir plus');
  String get seeLess => t('شوف قل', 'Voir moins');
  String get demoData => t('بيانات تجريبية', 'Données fictives');
  String get none => t('والو', '—');
  String percent(int p) => t('$p٪', '$p %');
  String yearsOld(int age) => t('$age سنة', '$age ans');

  String duration(int weeks) {
    if (weeks <= 1) return t('سيمانة', '1 semaine');
    if (weeks < 8) return t('$weeks سيمانات', '$weeks semaines');
    final months = (weeks / 4.33).round();
    if (!isAr) return '$months mois';
    if (months == 1) return 'شهر';
    if (months == 2) return 'شهرين';
    if (months <= 10) return '$months شهور';
    return '$months شهر';
  }

  // ── Welcome ───────────────────────────────────────────────────────────
  List<(String, String)> get welcomeSlides => [
    (
      t('فرص قريبة منك', 'Des opportunités près de chez vous'),
      t(
        'تكوينات، خدمات و برامج الدعم فتارودانت، أكادير و طاطا.',
        'Formations, emplois et dispositifs d\'accompagnement à Taroudant, Agadir et Tata.',
      ),
    ),
    (
      t('كيخدم حتى بلا أنترنيت', 'Fonctionne même sans connexion'),
      t(
        'الملف و المسار ديالك محفوظين فالتيليفون، و كيتزامنو ملي ترجع الكونيكسيون.',
        'Votre profil et votre parcours restent sur le téléphone et se synchronisent dès que le réseau revient.',
      ),
    ),
    (
      t('مساعد كيفهمك', 'Un assistant qui vous écoute'),
      t(
        'سول بالدارجة ولا بالفرنسية، و يقترح عليك اللي مناسب للملف ديالك.',
        'Posez vos questions en darija ou en français : il vous propose ce qui correspond à votre profil.',
      ),
    ),
  ];
  String get login => t('دخول', 'Se connecter');
  String get createAccount => t('صاوب حساب', 'Créer un compte');

  // ── Auth ──────────────────────────────────────────────────────────────
  String get loginTitle => t('مرحبا بيك من جديد', 'Bon retour parmi nous');
  String get loginSubtitle => t('دخل باش تكمل المسار ديالك', 'Connectez-vous pour reprendre votre parcours');
  String get identifier => t('رقم التيليفون ولا الإيمايل', 'Téléphone ou e-mail');
  String get password => t('الكود السري', 'Mot de passe');
  String get noAccount => t('ما عندكش حساب؟', 'Pas encore de compte ?');
  String get haveAccount => t('عندك حساب؟', 'Déjà inscrit·e ?');
  String get demoAccount => t('حساب تجريبي', 'Compte de démonstration');
  String get demoAccountHint =>
      t('شهد، 21 عام، تارودانت — كليكي باش يتعمر', 'Chahd, 21 ans, Taroudant — touchez pour remplir');
  String get registerTitle => t('حساب جديد', 'Créer votre compte');
  String get registerSubtitle => t('دقيقة وحدة و تبدا', 'Une minute pour commencer');
  String get fullName => t('السمية الكاملة', 'Nom complet');
  String get consent => t(
    'كنقبل تيفاوت يستعمل المعطيات ديالي غير باش يقترح عليا الفرص (القانون 09-08).',
    'J\'accepte que TIFAWT utilise mes données uniquement pour me proposer des opportunités (loi 09-08).',
  );
  String get errRequired => t('خاصك تعمر هاد الخانة', 'Ce champ est obligatoire');
  String get errIdentifier => t('دخل رقم تيليفون ولا إيمايل صحيح', 'Entrez un numéro ou un e-mail valide');
  String get errPasswordShort => t('الكود خاصو 6 حروف ولا كثر', 'Au moins 6 caractères');
  String get errWrongCredentials => t('المعلومات ماشي صحيحة', 'Identifiant ou mot de passe incorrect');
  String get errAccountExists => t('هاد الحساب كاين، دخل مباشرة', 'Ce compte existe déjà, connectez-vous');
  String get errConsent => t('خاصك توافق باش تكمل', 'Votre accord est nécessaire pour continuer');

  // ── Profile questionnaire ─────────────────────────────────────────────
  String get setupTitle => t('نتعرفو عليك', 'Faisons connaissance');
  String get editTitle => t('تعديل الملف', 'Modifier mon profil');
  String get draftNotice => t(
    'عمرنا اللي عندنا — راجعو و صحح إلا خاص.',
    'Nous avons prérempli ce que nous savons : vérifiez et corrigez si besoin.',
  );
  String stepOf(int a, int b) => t('المرحلة $a من $b', 'Étape $a sur $b');
  List<String> get setupSteps => [
    t('معلومات عامة', 'Informations générales'),
    t('القراية و الوضعية', 'Études et situation'),
    t('الهدف ديالك', 'Votre objectif'),
    t('الاهتمامات و المهارات', 'Intérêts et compétences'),
    t('الظروف ديالك', 'Vos contraintes'),
  ];
  String get sex => t('الجنس', 'Sexe');
  String get age => t('العمر', 'Âge');
  String get province => t('الإقليم', 'Province');
  String get commune => t('الجماعة', 'Commune');
  String get situation => t('الوضعية دابا', 'Situation actuelle');
  String get education => t('المستوى الدراسي', "Niveau d'études");
  String get lastDiploma => t('آخر شهادة', 'Dernier diplôme');
  String get vocational => t('تكوين مهني (إلا كان)', 'Formation professionnelle (facultatif)');
  String get vocationalHint => t('مثلا: حلاقة، 6 شهور', 'Ex. : coiffure, 6 mois');
  String get objective => t('شنو بغيتي توصل ليه؟', 'Quel est votre objectif ?');
  String get interests => t('المجالات اللي كتعجبك', "Centres d'intérêt");
  String get skills => t('شنو كتعرف دير', 'Compétences');
  String get mobility => t('فين تقدر تتنقل؟', 'Jusqu\'où pouvez-vous vous déplacer ?');
  String get internet => t('الأنترنيت عندك', 'Accès à internet');
  String get connection => t('نوع الكونيكسيون', 'Type de connexion');
  String get availability => t('الوقت اللي عندك', 'Disponibilité');
  String get modalityPref => t('حضوري ولا عن بعد؟', 'Présentiel ou à distance ?');
  String get multiHint => t('تقدر تختار بزاف', 'Plusieurs choix possibles');
  String get pickAtLeastOne => t('ختار وحدة على الأقل', 'Choisissez au moins un élément');
  String get finishSetup => t('سجل الملف', 'Enregistrer mon profil');
  String get saveChanges => t('سجل التعديلات', 'Enregistrer');

  // ── Home ──────────────────────────────────────────────────────────────
  String greeting(String name) => t('السلام عليكم، $name 👋', 'Bonjour $name 👋');
  String get searchHint => t('مراكز، برامج، فرص...', 'Centres, programmes, offres...');
  String get yourProvince => t('الإقليم ديالك', 'Votre province');
  String get whatToday => t('شنو بغيتي دير اليوم', "Que souhaitez-vous faire aujourd'hui ?");
  String get cardAssistant => t('المساعد ديالي', 'Mon assistant');
  String get cardAssistantSub => t('سول على التكوين، الخدمة ولا الدعم', 'Posez vos questions');
  String get cardRecommendations => t('التوصيات', 'Mes recommandations');
  String cardRecommendationsSub(int count, int best) =>
      t('$count فرص مناسبة ليك · الأحسن $best٪', "$count offres · jusqu'à $best %");
  String get cardOpportunities => t('الفرص', 'Mes opportunités');
  String get cardOpportunitiesSub => t('تكوينات، خدمات و برامج الدعم', 'Formations, emplois, aides');
  String get cardProgress => t('التقدم ديالي', 'Ma progression');
  String cardProgressSub(int p, String step) => t('$p٪ · المرحلة: $step', '$p % · étape : $step');
  String get cardProfile => t('الملف ديالي', 'Mon profil');
  String get cardProfileSub => t('المعلومات و الأهداف ديالك', 'Vos informations');

  // ── Connectivity & sync ───────────────────────────────────────────────
  String get offlineTitle => t('بلا كونيكسيون', 'Hors connexion');
  String get offlineBody => t(
    'المعطيات ديالك غادي تتزامن ملي ترجع الكونيكسيون.',
    'Vos données seront synchronisées lorsque la connexion sera disponible.',
  );
  String get reconnected => t('رجعات الكونيكسيون', 'Connexion rétablie');
  String get syncing => t('المزامنة جارية...', 'Synchronisation en cours...');
  String syncingCount(int n) => t('كنصيفطو $n عمليات', '$n action${n > 1 ? 's' : ''} en cours d\'envoi');
  String get syncDone => t('المزامنة سالات', 'Synchronisation terminée');
  String get syncFailed =>
      t('ما قدرناش نتزامنو — غادي نعاودو', 'Synchronisation impossible — nouvel essai bientôt');
  String get savedOffline => t('تسجلات بلا كونيكسيون', 'Action enregistrée hors connexion');
  String get savedOfflineBody =>
      t('غادي تتزامن ملي ترجع الكونيكسيون.', 'Elle sera synchronisée dès que la connexion sera disponible.');
  String pending(int n) => t('$n فالانتظار', '$n en attente');
  String get synced => t('متزامن', 'Synchronisé');
  String lastSyncAt(String when) => t('آخر مزامنة: $when', 'Dernière synchronisation : $when');

  // ── Navigation ────────────────────────────────────────────────────────
  String get navHome => t('الرئيسية', 'Accueil');
  String get navPlaces => t('الأماكن', 'Lieux');
  String get navOpportunities => t('الفرص', 'Offres');
  String get navAccount => t('حسابي', 'Parcours');

  // ── Assistant ─────────────────────────────────────────────────────────
  String get assistantTitle => t('المساعد الرقمي', 'Assistant TIFAWT');
  String get alwaysOnline => t('متصل دائما', 'Toujours disponible');
  String get typeMessage => t('كتب الرسالة ديالك...', 'Écrivez votre message...');
  String get seeAdapted => t('شوف الفرص المناسبة ليا', 'Voir mes opportunités adaptées');
  String get open => t('حل', 'Ouvrir');
  String get voiceSoonTitle => t('الصوت جاي قريبا', 'La voix arrive bientôt');
  String get voiceSoonBody => t(
    'من بعد غادي تقدر تهضر عوض ما تكتب، و تسمع الجواب. هاد الميزة مبرمجة فنسخة جاية حيت كتحتاج الأنترنيت، و المساعد دابا خدام بلا بيها.',
    'Bientôt, vous pourrez parler au lieu d\'écrire et écouter la réponse. Cette fonction est prévue dans une prochaine version car elle nécessite une connexion ; l\'assistant actuel fonctionne sans.',
  );

  // ── Recommendations ───────────────────────────────────────────────────
  String get recoTitle => t('التوصيات ديالي', 'Mes recommandations');
  String get recoSubtitle => t('محسوبة حسب الملف ديالك', 'Calculées à partir de votre profil');
  String recoUpdated(String when) => t('تحدثات $when', 'Mises à jour le $when');
  String get compatibility => t('التوافق', 'Compatibilité');
  String get whyThis => t('علاش هاد الاقتراح؟', 'Pourquoi cette recommandation ?');
  String get toNote => t('خاصك تعرف', 'À noter');
  String get viewOpportunity => t('شوف الفرصة', "Voir l'opportunité");
  String get howComputed => t('كيفاش كنحسبو التوافق؟', 'Comment le score est-il calculé ?');
  String get howComputedBody => t(
    'كل فرصة كنقارنوها مع الملف ديالك على 6 معايير. ما كاين حتى ذكاء غامض: كل نتيجة كنشرحو ليك علاش.',
    'Chaque opportunité est comparée à votre profil sur 6 critères pondérés. Aucune boîte noire : chaque résultat est expliqué.',
  );
  List<String> get weightLabels => [
    t('الهدف', 'Objectif'),
    t('المستوى', 'Niveau'),
    t('الاهتمامات', 'Intérêts'),
    t('المهارات', 'Compétences'),
    t('القرب', 'Proximité'),
    t('الظروف', 'Contraintes'),
  ];
  String get fromYourQuestion => t('حسب السؤال ديالك', 'Selon votre demande');
  String get showAll => t('شوف كلشي', 'Tout afficher');
  String get nearYou => t('قريب منك', 'Près de chez vous');
  String get noRecommendations => t('ما لقينا والو بهاد الشروط', 'Aucun résultat avec ces critères');
  String get placeLabel => t('البلاصة', 'Lieu');
  String get levelLabel => t('المستوى', 'Niveau');
  String get typeLabel => t('النوع', 'Type');
  String get durationLabel => t('المدة', 'Durée');
  String get online => t('أونلاين', 'En ligne');

  String reasonObjective(Objective o) => switch (o) {
    Objective.training => t('كتوافق الهدف ديالك: التكوين', 'Correspond à votre objectif de formation'),
    Objective.employment => t('كتوافق الهدف ديالك: الخدمة', "Correspond à votre objectif d'emploi"),
    Objective.studies => t('كتوافق الهدف ديالك: القراية', 'Correspond à votre projet de reprise d\'études'),
    Objective.entrepreneurship => t(
      'كتوافق المشروع ديالك',
      'Correspond à votre projet de création d\'activité',
    ),
    Objective.skills => t(
      'كتعاونك تطور المهارات ديالك',
      'Correspond à votre objectif de développer vos compétences',
    ),
  };
  String reasonInterests(String list) =>
      t('كتوافق الاهتمامات ديالك ($list)', "Correspond à vos centres d'intérêt ($list)");
  String get reasonLevel => t('مناسبة للمستوى ديالك', 'Adaptée à votre niveau');
  String reasonZone(String place) => t('قريبة منك ($place)', 'Accessible dans votre zone ($place)');
  String get reasonRemote => t('تقدر تتبعها من الدار', 'Accessible à distance');
  String reasonSkills(String list) =>
      t('كتستافد من المهارات ديالك ($list)', 'Valorise vos compétences ($list)');
  String get reasonLowInternet => t('ما كتحتاجش بزاف ديال الأنترنيت', 'Peu de connexion internet nécessaire');
  String warnTravel(String place) => t('خاصك تتنقل ل$place', 'Nécessite de se déplacer à $place');
  String get warnInternet => t('كتحتاج أنترنيت مستقر', 'Demande une connexion internet régulière');
  String warnLevel(String level) => t('المستوى المطلوب: $level', 'Niveau demandé : $level');
  String warnAge(int min, int max) => t('خاصة بـ $min–$max عام', 'Réservée aux $min–$max ans');
  String warnDeadline(String date) => t('آخر أجل قريب: $date', 'Date limite proche : $date');

  // ── Opportunities ─────────────────────────────────────────────────────
  String get opportunitiesTitle => t('الفرص المتاحة', 'Opportunités');
  String get filterAll => t('الكل', 'Toutes');
  String get filterRecommended => t('موصى بها', 'Recommandées');
  String get filterFree => t('مجانية', 'Gratuites');
  String get filterPaid => t('مدفوعة', 'Payantes');
  String get filterWomen => t('للنساء', 'Pour les femmes');
  String get filterSaved => t('المحفوظة', 'Enregistrées');
  String get free => t('مجاني', 'Gratuit');
  String get paid => t('مدفوع', 'Payant');
  String get noDiploma => t('بلا دبلوم', 'Sans diplôme');
  String get noResults => t('ما لقينا حتى فرصة', 'Aucune opportunité ne correspond');
  String get noResultsHint => t('بدل الفلتر ولا الكلمة', 'Essayez un autre filtre ou un autre mot');

  // ── Opportunity detail ────────────────────────────────────────────────
  String get about => t('على هاد الفرصة', 'Présentation');
  String get organization => t('الجهة', 'Organisme');
  String get location => t('البلاصة', 'Localisation');
  String get accessConditions => t('شروط الولوج', "Conditions d'accès");
  String get deadline => t('آخر أجل', 'Date limite');
  String get openAllYear => t('مفتوح طول العام', "Toute l'année");
  String get targetedSkills => t('المهارات المستهدفة', 'Compétences visées');
  String get modalities => t('الطريقة', 'Modalités');
  String get program => t('البرنامج', 'Programme');
  String get contact => t('التواصل', 'Contact');
  String get call => t('عيط', 'Appeler');
  String get officialSite => t('الولوج للموقع الرسمي', 'Accéder au site officiel');
  String get officialNote => t(
    'التسجيل النهائي كيكون عند الجهة الرسمية — تيفاوت كيوجهك.',
    'L\'inscription se fait auprès de l\'organisme officiel : TIFAWT vous oriente.',
  );
  String get availableOffline => t('متاحة بلا أنترنيت', 'Disponible hors connexion');
  String interested(bool female) =>
      g(female, arF: 'أنا مهتمة', arM: 'أنا مهتم', frF: 'Je suis intéressée', frM: 'Je suis intéressé');
  String get addedToJourney => t('تزادت للمسار ديالك', 'Opportunité ajoutée à votre parcours');
  String statusLine(String status) => t('الحالة: $status', 'Statut : $status');
  String get inYourJourney => t('فالمسار ديالك', 'Dans votre parcours');
  String get updateStatus => t('بدل الحالة', 'Mettre à jour le statut');
  String get statusUpdated => t('تبدلات الحالة', 'Statut mis à jour');
  String get cannotOpenLink => t('ما قدرناش نحلو الرابط', "Impossible d'ouvrir le lien");

  // ── Journey / progression ─────────────────────────────────────────────
  String get myPathTitle => t('المسار ديالي', 'Mon parcours');
  String get progressLabel => t('التقدم', 'Progression');
  String progressOf(int done, int total) => t('$done من $total مراحل', '$done étapes sur $total');
  String get timeline => t('السجل الزمني', 'Étapes du parcours');
  String get stepDone => t('انتهى', 'Terminé');
  String get stepCurrent => t('جاري الآن', 'En cours');
  String get stepPending => t('مازال', 'À venir');
  String get myOpportunity => t('الفرصة ديالي', 'Mon opportunité');
  String get noOpportunityYet =>
      t('مازال ما ختاريتي حتى فرصة', "Vous n'avez pas encore choisi d'opportunité");
  String get history => t('التاريخ', 'Historique');
  String get historyEmpty => t('مازال ما كاين والو', 'Rien pour le moment');
  String get badges => t('الأوسمة ديالي', 'Mes badges');
  String get badgeUnlocked => t('وسام جديد', 'Nouveau badge');
  String get documents => t('الوثائق ديالي', 'Mes documents');
  String get addDocument => t('زيد وثيقة', 'Ajouter un document');
  String get docReady => t('واجدة', 'Prête');
  String get docToPrepare => t('خاصها تتوجد', 'À préparer');
  String get docHint => t('كليكي على الوثيقة ملي توجدها', 'Touchez un document une fois prêt');
  String get statProgress => t('التقدم', 'Progression');
  String get statSaved => t('فرص محفوظة', 'Enregistrées');
  String get statBadges => t('أوسمة', 'Badges');
  String get syncLabel => t('المزامنة', 'Synchronisation');

  // ── Profile view ──────────────────────────────────────────────────────
  String get myProfile => t('الملف ديالي', 'Mon profil');
  String get edit => t('تعديل', 'Modifier');
  String get sectionGeneral => t('معلومات عامة', 'Informations générales');
  String get sectionEducation => t('القراية', 'Éducation');
  String get sectionObjective => t('الهدف', 'Objectif');
  String get sectionInterests => t('الاهتمامات و المهارات', 'Intérêts et compétences');
  String get sectionConstraints => t('الظروف', 'Contraintes');

  // ── Centers ───────────────────────────────────────────────────────────
  String get placesTitle => t('المراكز القريبة مني', 'Centres près de chez moi');
  String get openNow => t('مفتوح', 'Ouvert');
  String get closedNow => t('مسدود', 'Fermé');
  String km(double d) => t('${_num(d)} كلم', '${_num(d)} km');
  String hours(String from, String to) => t('$from الى $to', '$from – $to');
  String get askAssistantCta =>
      t('عندك سؤال؟ سول المساعد الرقمي ديالنا', 'Une question ? Demandez à notre assistant');
  String get services => t('الخدمات', 'Services');
  String get address => t('العنوان', 'Adresse');
  String get itinerary => t('الطريق', 'Itinéraire');
  String get yourCenter => t('المركز المرجعي ديالك', 'Votre structure de référence');
  String get antennasNote => t(
    'نقط تيفاوت فالدواوير: مبرمجة فالمرحلة الجاية.',
    'Antennes TIFAWT dans les douars : déploiement prévu dans une prochaine phase.',
  );

  // ── Settings ──────────────────────────────────────────────────────────
  String get settingsTitle => t('الإعدادات', 'Paramètres');
  String get languageLabel => t('اللغة', 'Langue');
  String get syncNow => t('تزامن دابا', 'Synchroniser maintenant');
  String get allSynced => t('كلشي متزامن', 'Tout est synchronisé');
  String get never => t('مازال', 'Jamais');
  String get lastSyncLabel => t('آخر مزامنة', 'Dernière synchronisation');
  String get serverLabel => t('السيرفور', 'Serveur');
  String get serverDemo => t('وضع العرض (سيرفور محاكي)', 'Mode démonstration (serveur simulé)');
  String get demoSection => t('العرض', 'Démonstration');
  String get simulateOffline => t('خدم كأنك بلا أنترنيت', 'Simuler le mode hors connexion');
  String get simulateOfflineHint =>
      t('مفيد ملي ما تقدرش تقطع الشبكة', 'Utile quand on ne peut pas couper le réseau');
  String get resetDemo => t('رجع الحساب التجريبي لبدايتو', 'Réinitialiser le compte de démonstration');
  String get resetDemoConfirm => t(
    'الملف، المسار و المحادثة ديال شهد غادي يرجعو لبدايتهم.',
    'Le profil, le parcours et la conversation de Chahd reviendront à leur état initial.',
  );
  String get resetDone => t('رجع الحساب التجريبي لبدايتو', 'Compte de démonstration réinitialisé');
  String get privacySection => t('المعطيات الشخصية', 'Données personnelles');
  String get viewData => t('شوف المعطيات ديالي', 'Consulter mes données');
  String get deleteData => t('مسح المعطيات ديالي', 'Supprimer mes données');
  String get deleteDataConfirm => t(
    'غادي نمسحو الحساب و كلشي اللي فالتيليفون. ما يمكنش ترجعو.',
    'Votre compte et toutes les données du téléphone seront supprimés. Cette action est définitive.',
  );
  String get legalNote => t(
    'هاد النسخة كتستعمل غير معطيات تجريبية. تيفاوت كياخد بعين الاعتبار القانون 09-08 و توصيات اللجنة الوطنية (CNDP)، و التحليل القانوني الكامل مبرمج قبل أي إطلاق.',
    'Cette version n\'utilise que des données fictives. TIFAWT prend en compte la loi 09-08 et les recommandations de la CNDP ; une analyse de conformité complète est prévue avant tout lancement.',
  );
  String get aboutSection => t('على تيفاوت', 'À propos');
  String get aboutBody => t(
    'تيفاوت كتعني "الضو" بالأمازيغية. التطبيق كيوجه، و الجهات المختصة هي اللي كتقدم الخدمة.',
    '« Tifawt » signifie « lumière » en amazighe. L\'application oriente ; les organismes spécialisés délivrent le service.',
  );
  String get roadmap => t('شنو جاي من بعد', 'Prochaines évolutions');
  List<String> get roadmapItems => [
    t('الصوت: تهضر و تسمع الجواب', 'Voix : parler et écouter les réponses'),
    t('مساعد أذكى مربوط بقاعدة المعارف', 'Assistant enrichi par une base de connaissances'),
    t('واجهة بالأمازيغية', 'Interface en amazighe'),
    t('نقط تيفاوت فالدواوير', 'Antennes TIFAWT dans les douars'),
  ];
  String get logout => t('الخروج من الحساب', 'Se déconnecter');
  String get logoutConfirm =>
      t('المعطيات ديالك غادي تبقى محفوظة فالتيليفون.', 'Vos données restent enregistrées sur le téléphone.');

  String _num(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
}
