import 'package:flutter_test/flutter_test.dart';
import 'package:tifawt/features/assistant/domain/assistant_provider.dart';
import 'package:tifawt/features/assistant/domain/intent_parser.dart';
import 'package:tifawt/features/assistant/domain/rule_based_assistant.dart';
import 'package:tifawt/features/progress/domain/journey.dart';
import 'package:tifawt/features/recommendations/domain/recommendation_engine.dart';
import 'package:tifawt/shared/models/app_user.dart';
import 'package:tifawt/shared/models/profile_enums.dart';

import 'support/fixtures.dart';

void main() {
  final faq = loadFaq();
  final parser = IntentParser(faqKeywords: {for (final f in faq) f.id: f.keywords});

  AssistantContext context({bool interfaceIsAr = true}) => AssistantContext(
    interfaceIsAr: interfaceIsAr,
    user: const AppUser(id: 'demo-chahd', name: 'شهد أمزيان', nameLatin: 'Chahd Amzian'),
    profile: chahd,
    ranked: const RecommendationEngine().rank(loadCatalog(), chahd, now: today),
    centers: loadCenters(),
    progress: computeJourney(profileCompleted: true, data: const JourneyData()),
    faq: faq,
  );

  group('intent analysis', () {
    test('the parcours sentence: training + digital + limited mobility, in French', () {
      final u = parser.parse(
        "Je cherche une formation en informatique mais je n'ai pas beaucoup de moyens pour me déplacer.",
        interfaceIsAr: true,
      );
      expect(u.intent, AssistantIntent.searchTraining);
      expect(u.domain, Interest.digital);
      expect(u.nearOnly, isTrue);
      expect(u.isAr, isFalse, reason: 'the reply follows the language of the message');
    });

    test('Darija in Arabic script', () {
      final u = parser.parse('بغيت نتكون فالمعلوميات قريب من الدار', interfaceIsAr: false);
      expect(u.intent, AssistantIntent.searchTraining);
      expect(u.domain, Interest.digital);
      expect(u.nearOnly, isTrue);
      expect(u.isAr, isTrue);
    });

    test('Darija written in Latin letters', () {
      final u = parser.parse('salam bghit khdma f taroudant', interfaceIsAr: false);
      expect(u.intent, AssistantIntent.searchJob);
      expect(u.isAr, isTrue);
    });

    test('the conversation of the design: feeling lost, then low confidence', () {
      expect(
        parser.parse('بصراحة أنا حاليا ماكنقراش وماخدامش، وحاسس براسي ضايع', interfaceIsAr: true).intent,
        AssistantIntent.lost,
      );
      expect(
        parser.parse('ما عرفتش بصراحة. حتى الثقة فراسي مبقاتش', interfaceIsAr: true).intent,
        AssistantIntent.lowConfidence,
      );
    });

    test('"parcours" is not mistaken for "cours"', () {
      expect(parser.parse('Où en est mon parcours ?', interfaceIsAr: false).intent, AssistantIntent.progress);
    });

    test('named programmes go to the knowledge base', () {
      final u = parser.parse("C'est quoi Awrach ?", interfaceIsAr: false);
      expect(u.intent, AssistantIntent.faq);
      expect(u.faqId, 'awrach');
    });
  });

  group('replies', () {
    const assistant = RuleBasedAssistant();

    test('answers the parcours request with adapted opportunities', () async {
      final reply = await assistant.reply(
        "Je cherche une formation en informatique mais je n'ai pas beaucoup de moyens pour me déplacer.",
        context(),
      );
      expect(
        reply.text,
        "D'après votre profil, je peux vous proposer des formations en numérique accessibles dans votre zone et adaptées à votre niveau.",
      );
      expect(reply.results.first.opportunity.id, 'op_numerique_init');
      expect(reply.results.first.score, 92);
      expect(reply.actionLabel, 'Voir mes opportunités adaptées');
      expect(reply.actionRoute, startsWith('/recommendations?'));
      expect(reply.understood, ['Formation', 'Numérique', 'Près de chez vous']);
    });

    test('never invents: every result exists in the catalog', () async {
      final ids = loadCatalog().map((o) => o.id).toSet();
      for (final message in ['bghit khdma', 'je veux créer mon projet', 'formation agriculture', 'stage']) {
        final reply = await assistant.reply(message, context());
        for (final r in reply.results) {
          expect(ids, contains(r.opportunity.id));
        }
      }
    });

    test('unclear request: asks for a precision', () async {
      final reply = await assistant.reply('hmm', context(interfaceIsAr: false));
      expect(reply.text, contains('cherchez-vous plutôt'));
      expect(reply.suggestions, hasLength(3));
    });

    test('nearest centre comes from local data', () async {
      final reply = await assistant.reply('فين أقرب مركز؟', context());
      expect(reply.text, contains('منصة الشباب تارودانت'));
      expect(reply.actionRoute, '/places');
    });
  });
}
