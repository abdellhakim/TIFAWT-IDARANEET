import '../../../shared/models/localized_text.dart';
import '../../../shared/models/support_center.dart';
import '../../recommendations/domain/opportunity_query.dart';
import '../../recommendations/domain/recommendation.dart';
import 'assistant_provider.dart';
import 'intent_parser.dart';

/// MVP assistant: question → intent analysis → search in the local
/// opportunity base → answer. Deterministic, offline, and it only ever
/// cites opportunities that exist in the catalog.
class RuleBasedAssistant implements AssistantProvider {
  const RuleBasedAssistant();

  @override
  String get id => 'rule-based';

  @override
  Future<AssistantReply> reply(String message, AssistantContext c) async {
    final parser = IntentParser(faqKeywords: {for (final f in c.faq) f.id: f.keywords});
    final u = parser.parse(message, interfaceIsAr: c.interfaceIsAr);
    String t(String ar, String fr) => u.isAr ? ar : fr;
    final female = c.profile?.isFemale ?? true;
    final name = c.user?.firstName(u.isAr) ?? '';

    switch (u.intent) {
      case AssistantIntent.greeting:
        return AssistantReply(
          text: t(
            'السلام${name.isEmpty ? '' : ' $name'}، أنا المساعد الرقمي 👋 كيفاش نقدر نعاونك اليوم؟',
            "Bonjour${name.isEmpty ? '' : ' $name'}, je suis l'assistant TIFAWT. Comment puis-je vous aider aujourd'hui ?",
          ),
          suggestions: _starters(u.isAr),
        );

      case AssistantIntent.thanks:
        return AssistantReply(
          text: t(
            'بالتوفيق! أنا هنا فأي وقت، حتى بلا أنترنيت.',
            'Avec plaisir ! Je reste disponible à tout moment, même sans connexion.',
          ),
        );

      case AssistantIntent.lost:
        return AssistantReply(
          text: t(
            'فهمتك، وماشي بوحدك فهاد الحالة. بزاف ديال الشباب كيدوزو من هاد المرحلة',
            'Je vous comprends, et vous n\'êtes pas ${female ? 'seule' : 'seul'} dans cette situation. Beaucoup de jeunes passent par cette étape.',
          ),
          suggestions: u.isAr
              ? const ['ما عرفتش منين نبدا', 'بغيت نتكون']
              : const ['Je ne sais pas par où commencer', 'Je veux me former'],
        );

      case AssistantIntent.lowConfidence:
        return AssistantReply(
          text: t(
            'واش بغيتي نعاونك تلقى خدمة، ولا تكمل قرايتك، ولا غير تهضر مع شي حد؟',
            'Voulez-vous que je vous aide à trouver un emploi, à reprendre vos études, ou simplement à parler avec quelqu\'un ?',
          ),
          suggestions: u.isAr
              ? const ['بغيت نلقى خدمة', 'بغيت نكمل قرايتي', 'بغيت نهضر مع شي حد']
              : const ['Trouver un emploi', 'Reprendre mes études', "Parler avec quelqu'un"],
        );

      case AssistantIntent.counselor:
        final center = _homeCenter(c.centers);
        if (center == null) break;
        return AssistantReply(
          text: t(
            'تقدر تلاقى مستشار فـ${center.name.ar}، على بعد ${_km(center.distanceKm)} كلم. الاستقبال مجاني و بلا موعد، من ${center.opensAt} حتى ${center.closesAt}.',
            'Un conseiller peut vous recevoir à ${center.name.fr}, à ${_km(center.distanceKm)} km. L\'accueil est gratuit et sans rendez-vous, de ${center.opensAt} à ${center.closesAt}.',
          ),
          actionLabel: t('شوف المركز', 'Voir le centre'),
          actionRoute: '/places',
        );

      case AssistantIntent.centers:
        final center = _homeCenter(c.centers);
        if (center == null) break;
        return AssistantReply(
          text: t(
            'أقرب مركز ليك هو ${center.name.ar}، على بعد ${_km(center.distanceKm)} كلم. مفتوح من ${center.opensAt} حتى ${center.closesAt}.',
            'La structure la plus proche est ${center.name.fr}, à ${_km(center.distanceKm)} km. Elle est ouverte de ${center.opensAt} à ${center.closesAt}.',
          ),
          actionLabel: t('شوف الخريطة', 'Voir la carte'),
          actionRoute: '/places',
        );

      case AssistantIntent.progress:
        final p = c.progress;
        final current = p.current?.id.label(u.isAr);
        return AssistantReply(
          text: current == null
              ? t(
                  'مبروك! كملتي جميع المراحل ديال المسار.',
                  'Bravo, vous avez validé toutes les étapes de votre parcours !',
                )
              : t(
                  'كملتي ${p.done} من ${p.total} مراحل (${p.percent}٪). المرحلة الجاية: $current.',
                  'Vous avez validé ${p.done} étapes sur ${p.total} (${p.percent} %). Prochaine étape : $current.',
                ),
          actionLabel: t('شوف المسار ديالي', 'Voir mon parcours'),
          actionRoute: '/account',
        );

      case AssistantIntent.faq:
        final entry = c.faq.firstWhere((f) => f.id == u.faqId);
        final linked = entry.opportunityId == null
            ? const <Recommendation>[]
            : c.ranked.where((r) => r.opportunity.id == entry.opportunityId).toList();
        return AssistantReply(
          text: entry.answer.of(u.isAr),
          results: linked,
          suggestions: entry.suggestions.of(u.isAr),
          actionLabel: entry.route == null ? null : t('حل', 'Ouvrir'),
          actionRoute: entry.route,
        );

      case AssistantIntent.searchTraining:
      case AssistantIntent.searchJob:
      case AssistantIntent.searchInternship:
      case AssistantIntent.entrepreneurship:
      case AssistantIntent.support:
      case AssistantIntent.studies:
      case AssistantIntent.recommend:
      case AssistantIntent.explore:
        return _search(u, c);

      case AssistantIntent.unknown:
        break;
    }

    return AssistantReply(
      text: t(
        'باش نعاونك مزيان: واش كتقلب على تكوين، خدمة، ولا مواكبة باش تبدا مشروع؟',
        'Pour bien vous aider : cherchez-vous plutôt une formation, un emploi ou un accompagnement pour créer votre activité ?',
      ),
      suggestions: u.isAr
          ? const ['بغيت نتكون', 'بغيت نلقى خدمة', 'بغيت نبدا مشروع']
          : const ['Je cherche une formation', 'Je cherche un emploi', 'Je veux créer mon activité'],
    );
  }

  AssistantReply _search(Understanding u, AssistantContext c) {
    String t(String ar, String fr) => u.isAr ? ar : fr;
    final profile = c.profile;

    final query = OpportunityQuery(
      scope: switch (u.intent) {
        AssistantIntent.searchTraining => QueryScope.training,
        AssistantIntent.searchJob => QueryScope.job,
        AssistantIntent.searchInternship => QueryScope.internship,
        AssistantIntent.entrepreneurship => QueryScope.entrepreneurship,
        AssistantIntent.support => QueryScope.support,
        AssistantIntent.studies => QueryScope.studies,
        _ => QueryScope.all,
      },
      interest: u.domain,
      nearOnly: u.nearOnly,
      freeOnly: u.freeOnly,
    );

    final understood = [
      if (_scopeChip(query.scope) case final chip?) chip.of(u.isAr),
      if (u.domain != null) u.domain!.label(u.isAr),
      if (u.nearOnly) t('قريب منك', 'Près de chez vous'),
      if (u.freeOnly) t('مجاني', 'Gratuit'),
    ];

    if (profile == null) {
      return AssistantReply(
        text: t(
          'كمل الملف ديالك باش نقدر نقترح عليك اللي مناسب ليك.',
          'Complétez votre profil pour que je puisse vous proposer ce qui vous correspond.',
        ),
        understood: understood,
        actionLabel: t('كمل الملف', 'Compléter mon profil'),
        actionRoute: '/profile/edit',
      );
    }

    var results = [
      for (final r in c.ranked)
        if (query.matches(r, profile)) r,
    ];
    if (u.women) {
      results.sort((a, b) => (b.opportunity.forWomen ? 1 : 0) - (a.opportunity.forWomen ? 1 : 0));
    }
    results = results.take(3).toList();

    final noun = query.scope.label(u.isAr);
    final domainAr = u.domain == null ? '' : ' ف${u.domain!.ar}';
    final domainFr = u.domain == null ? '' : ' en ${u.domain!.fr.toLowerCase()}';

    if (results.isEmpty) {
      final fallback = c.ranked
          .where((r) => OpportunityQuery(scope: query.scope).matches(r, profile))
          .take(3)
          .toList();
      return AssistantReply(
        text: t(
          'ما لقيتش $noun$domainAr بهاد الشروط دابا. هادو أقرب حوايج للملف ديالك:',
          "Je n'ai pas trouvé de $noun$domainFr avec ces critères pour l'instant. Voici ce qui se rapproche le plus de votre profil :",
        ),
        understood: understood,
        results: fallback,
        actionLabel: t('شوف التوصيات ديالي', 'Voir mes recommandations'),
        actionRoute: const OpportunityQuery().route(),
      );
    }

    final text = u.nearOnly
        ? t(
            'حسب الملف ديالك، نقدر نقترح عليك $noun$domainAr قريبة منك و مناسبة للمستوى ديالك.',
            'D\'après votre profil, je peux vous proposer des $noun$domainFr accessibles dans votre zone et adaptées à votre niveau.',
          )
        : t(
            'حسب الملف ديالك، هادي أحسن $noun$domainAr ليك:',
            'D\'après votre profil, voici les $noun$domainFr qui vous correspondent le mieux :',
          );

    return AssistantReply(
      text: text,
      understood: understood,
      results: results,
      actionLabel: t('شوف الفرص المناسبة ليا', 'Voir mes opportunités adaptées'),
      actionRoute: query.route(),
    );
  }

  static LocalizedText? _scopeChip(QueryScope scope) => switch (scope) {
    QueryScope.training => const LocalizedText('تكوين', 'Formation'),
    QueryScope.job => const LocalizedText('خدمة', 'Emploi'),
    QueryScope.internship => const LocalizedText('تدريب', 'Stage'),
    QueryScope.entrepreneurship => const LocalizedText('مقاولة', 'Entrepreneuriat'),
    QueryScope.support => const LocalizedText('دعم', 'Aides'),
    QueryScope.studies => const LocalizedText('قراية', 'Études'),
    QueryScope.all => null,
  };

  static List<String> _starters(bool isAr) => isAr
      ? const ['بغيت نتكون فالمعلوميات', 'بغيت نلقى خدمة', 'فين أقرب مركز؟']
      : const [
          'Je cherche une formation en informatique',
          'Je cherche un emploi',
          'Où est le centre le plus proche ?',
        ];

  static SupportCenter? _homeCenter(List<SupportCenter> centers) {
    if (centers.isEmpty) return null;
    return centers.firstWhere(
      (c) => c.isHome,
      orElse: () => centers.reduce((a, b) => a.distanceKm <= b.distanceKm ? a : b),
    );
  }

  static String _km(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
}
