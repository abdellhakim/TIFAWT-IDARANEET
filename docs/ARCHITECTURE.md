# Architecture technique — TIFAWT

Version de travail, octobre 2026. Ce document décrit ce qui est **réellement implémenté**
dans ce dépôt et le relie aux spécifications techniques (numéros de section entre crochets).

## Vue d'ensemble [§2]

```
             Jeune NEET
                 │
        Application mobile (Flutter)
        ┌────────┼─────────────┐
        ▼        ▼             ▼
      Hive   Network       Sync Manager
     (local) Manager      (file d'attente)
                 └──────┬──────┘
                        ▼
                API REST Flask (JWT)
        ┌───────────────┼────────────────┐
        ▼               ▼                ▼
   PostgreSQL   Moteur de reco.   Service assistant
                (règles pondérées)  ├── base de connaissances
                                    └── fournisseurs LLM (évolution)
```

**Choix du framework mobile.** La spécification mentionne React Native ; le prototype est en
**Flutter**, qui est l'écosystème natif de Hive (base locale retenue par la spécification),
compile une seule base de code pour Android, iOS et le web, et gère nativement la mise en page
de droite à gauche pour l'arabe. Le reste de l'architecture est inchangé.

## Organisation du code [§4]

```
lib/core/        network/        client HTTP, jeton JWT, rafraîchissement
                 storage/        boîtes Hive, chiffrement, données de démonstration
                 authentication/ hachage PBKDF2 des mots de passe
                 localization/   arabe (darija) et français, sens d'écriture
                 connectivity/   détection réseau + mode hors connexion simulé
lib/features/    auth · onboarding · profile · recommendations · opportunities · assistant
                 progress · badges · centers · synchronization · home · settings · shell
                 (chaque fonctionnalité : domain / data / application / presentation)
lib/shared/      components · models · constants · utils
```

Pattern MVVM : les écrans (vues) lisent des `Notifier` Riverpod (modèles de vue) qui passent par
des dépôts ; aucune logique métier dans les widgets. Le domaine (moteur de recommandation,
analyse d'intention, calcul du parcours) est en Dart pur et testé sans interface.

## Stockage local [§5]

Boîtes Hive : `tf_profiles` (UserProfile), `tf_catalog` (OpportunityCache), `tf_recommendations`
(RecommendationCache), `tf_journey` (Progress), `tf_badges`, `tf_chat` (ChatHistory),
`tf_sync_queue` (SyncQueue), `tf_settings` (AppSettings), plus `tf_auth`, `tf_favorites`,
`tf_documents`, `tf_centers` et `tf_knowledge` (FAQ).

Les boîtes contenant des données personnelles sont **chiffrées en AES-256** ; la clé est rangée
dans le coffre du système (Android Keystore, Trousseau iOS, WebCrypto) [§8, §32]. Le catalogue
est fourni avec l'application (`assets/data/*.json`) : un premier lancement sans réseau est
pleinement utilisable.

## Authentification [§8]

- Identifiant : numéro de téléphone **ou** e-mail.
- Le compte est vérifié sur l'appareil (hachage PBKDF2-HMAC-SHA256, sel aléatoire), donc la
  connexion marche hors ligne.
- Quand l'API est joignable, l'application obtient un **JWT** (accès 1 h, rafraîchissement
  30 jours) conservé dans le coffre sécurisé. Un compte créé hors ligne est enregistré côté
  serveur à la reconnexion, avec le même identifiant.
- Côté serveur : hachage Werkzeug, rôles `youth`, `association`, `institution`, `company`,
  `admin` portés par le jeton [§30] ; `GET /api/admin/stats` est réservé aux rôles institutionnels
  et ne renvoie que des agrégats.

## Hors connexion et synchronisation [§9, §10]

Chaque modification locale ajoute une opération à la file :

```json
{ "id": "…", "entity": "application", "operation": "UPDATE",
  "timestamp": "2026-10-10T10:05:00Z", "payload": { "opportunityId": "…", "status": "registered" } }
```

À la reconnexion : détection → lecture de la file → envoi (`POST /api/sync`) → validation et
mise à jour PostgreSQL → confirmation opération par opération → suppression locale. Les
opérations refusées ou non confirmées restent dans la file et sont réessayées (15 s).
Le serveur enregistre chaque identifiant dans `sync_logs` : rejouer un lot est sans effet
(idempotence), et un statut plus ancien n'écrase jamais un statut plus récent (horodatage
de l'appareil). L'interface affiche « Hors connexion », « Action enregistrée hors connexion »,
« Connexion rétablie », « Synchronisation en cours… », « Synchronisation terminée ».

Sans `TIFAWT_API_URL`, la même file est vidée par un serveur simulé (mode démonstration).

## Profil [§11]

Informations générales (âge, sexe, province, commune, situation), éducation (niveau, dernier
diplôme, formation professionnelle), objectif, intérêts, compétences et contraintes (mobilité,
accès internet, type de connexion, disponibilité, présentiel/distanciel).

## Moteur de recommandation [§12–§14]

`lib/features/recommendations/domain/recommendation_engine.dart` et son miroir
`backend/app/recommendation.py` :

```
Score = 25 % objectif + 20 % niveau + 20 % intérêts + 15 % compétences
      + 10 % proximité + 10 % contraintes          (normalisé sur 100)
```

Chaque critère produit des **raisons** (« Correspond à votre objectif de formation »,
« Accessible dans votre zone ») et des **points d'attention** (déplacement, internet régulier,
niveau, âge, date limite). Les offres dont la date limite est passée sont écartées. Un test de
parité garantit que l'application et le serveur donnent le même score (92 % pour l'exemple du
parcours nominal).

## Assistant [§16–§20]

**MVP (implémenté).** Question → détection de la langue (arabe, darija en lettres latines,
français) → intention (formation, emploi, stage, entrepreneuriat, aides, études, centres,
progression, FAQ, soutien) → domaine et contraintes (proximité, gratuité) → recherche dans le
catalogue local classé par le moteur → réponse. L'assistant demande une précision quand la
demande est floue et ne peut citer que des offres existantes. Il tourne entièrement sur le
téléphone.

**Évolution (préparée côté API).** `backend/app/assistant.py` définit l'abstraction
`AssistantService` avec `RuleBasedAssistant` (par défaut), `OpenAIProvider` (Responses API) et
`LocalLLMProvider` (modèle souverain exposant une API compatible). Les fournisseurs LLM reçoivent
le prompt système de la spécification, le profil et le contexte récupéré (FAQ + offres
correspondantes), et retombent sur la réponse à base de règles en cas d'erreur. **Aucune clé
n'est présente dans l'application mobile.** L'usage d'un service cloud ne garantit pas la
résidence des données au Maroc : le choix du fournisseur reste à valider.

## Voix [§21–§24]

Hors parcours MVP : le micro de l'assistant explique que la fonction est prévue. La chaîne
cible (STT → assistant → TTS) passera par l'API, pour la même raison de sécurité des clés.

## Opportunités et accès aux formations [§25–§26]

Chaque offre porte : id, titre, description, type, organisme, lieu, niveau requis, compétences,
intérêts, objectifs, durée, date limite, internet requis, mobilité requise, modalité, âge,
lien officiel, contact. TIFAWT oriente ; l'inscription se fait sur la plateforme de l'organisme
(« Accéder au site officiel »).

## Progression et badges [§27–§28]

Étapes : Profil complété → Orientation → Opportunité sélectionnée → Inscription → Formation →
Certification, **déduites des actions réelles** (jamais saisies à la main). Statuts d'une offre :
intéressée, inscription effectuée, en formation, formation terminée, certification obtenue.
Badges : `PROFILE_COMPLETED`, `FIRST_RECOMMENDATION`, `FIRST_OPPORTUNITY`, `TRAINING_STARTED`,
`TRAINING_COMPLETED`.

## Centres [§29]

Centres, associations et agences avec adresse, horaires (état ouvert/fermé calculé), services
et contact, sur une carte dessinée qui fonctionne sans tuiles ni clé d'API. Données fictives,
signalées comme telles ; les antennes TIFAWT sont présentées comme une évolution.

## API [§7, §31]

| Méthode | Route | |
|---|---|---|
| POST | `/api/auth/register`, `/api/auth/login`, `/api/auth/refresh` | JWT |
| GET / PUT | `/api/profile` | |
| GET | `/api/opportunities` | public, filtre `?province=` |
| GET | `/api/recommendations` | score, raisons, avertissements |
| GET / POST | `/api/progress` | |
| GET | `/api/badges`, `/api/centers` | |
| POST | `/api/assistant/message` | fournisseur configurable |
| POST | `/api/sync` | lot d'opérations, résultats par opération |
| GET | `/api/admin/stats` | rôles institutionnels |

## Protection des données [§32–§33]

Données fictives uniquement pour la démonstration. Consentement explicite à l'inscription,
chiffrement local, consultation et suppression des données depuis les paramètres, statistiques
agrégées seulement. TIFAWT **prend en compte** la loi 09-08 et les recommandations de la CNDP ;
la conformité juridique n'est pas revendiquée tant qu'une analyse formelle n'a pas été menée.

## Hébergement [§34]

`docker-compose.yml` décrit l'API (gunicorn) et PostgreSQL 16 ; non testé sur la machine de
développement (Docker absent). En production : HTTPS, passerelle, sauvegardes et supervision,
hébergeur choisi selon la localisation des données.

## Statut des composants [§36]

| Composant | Technologie | Statut |
|---|---|---|
| Mobile | Flutter, Clean Architecture + feature-first + MVVM (Riverpod) | MVP |
| Stockage local | Hive chiffré | MVP |
| Backend / API | Python Flask, REST, JWT | MVP |
| Base de données | PostgreSQL (SQLite en développement) | Cible |
| Recommandation | Règles pondérées explicables | MVP |
| Assistant | Texte, intentions + base de connaissances | MVP |
| Synchronisation | File d'attente, idempotente | MVP |
| Gamification | Badges et progression | MVP |
| RAG / LLM | Abstraction de fournisseurs côté API | Évolution |
| Voix (STT/TTS) | Via l'API | Évolution |
| Darija avancée, amazighe | À valider | Évolution |
| Antennes, statistiques avancées | Module préparé | Évolution |
