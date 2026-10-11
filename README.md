# TIFAWT · ⵜⵉⴼⴰⵡⵜ

**Votre passerelle vers les opportunités** — programme IDARANEET, Souss-Massa.

TIFAWT (« la lumière » en amazighe) accompagne les jeunes NEET de Taroudant, Agadir et Tata :
profil, recommandations expliquées, assistant conversationnel, suivi du parcours… et tout
continue de fonctionner sans connexion. Les actions faites hors ligne sont mises en file
d'attente puis synchronisées dès que le réseau revient.

> Toutes les données de cette version (offres, centres, persona) sont **fictives mais
> réalistes**. Les organismes cités existent ; les offres sont inventées pour la démonstration.

## Compte de démonstration

| Identifiant | Mot de passe |
|---|---|
| `0600000000` **ou** `chahd@tifawt.ma` | `123456` |

Chahd, 21 ans, Bac, Taroudant, cherche une formation et se déplace peu. Son questionnaire
est pré-rempli mais pas encore validé, pour montrer l'étape « profil » sans tout ressaisir.
L'écran de connexion propose une carte qui remplit les identifiants d'un geste, et
**Paramètres → Réinitialiser le compte de démonstration** remet tout à zéro entre deux
répétitions. Le déroulé complet devant le jury est dans [docs/PARCOURS_DEMO.md](docs/PARCOURS_DEMO.md).

## Lancer l'application

Prérequis : Flutter 3.44+ (Dart 3.12).

```bash
flutter pub get
flutter run                 # téléphone ou émulateur
flutter run -d chrome       # aperçu dans le navigateur
```

Sans autre option, l'application est **autonome** : la synchronisation passe par un serveur
simulé, idéal pour une démonstration sans réseau fiable. Pour la relier à l'API réelle :

```bash
flutter run --dart-define=TIFAWT_API_URL=http://10.0.2.2:5000   # émulateur Android
flutter run --dart-define=TIFAWT_API_URL=http://192.168.1.20:5000   # téléphone sur le même Wi-Fi
```

APK à installer sur un téléphone :

```bash
flutter build apk --release
```

Le fichier se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.

## Lancer l'API (Flask)

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate          # Windows  (source .venv/bin/activate sous Linux/macOS)
pip install -r requirements-dev.txt
python run.py                   # http://localhost:5000, SQLite par défaut
pytest                          # 15 tests
```

PostgreSQL (cible) : définir `DATABASE_URL`, ou `docker compose up --build` à la racine
(fichier fourni, à adapter selon l'hébergement). Détails dans [backend/README.md](backend/README.md).

## Ce que fait l'application

| Parcours | Écran | Points clés |
|---|---|---|
| Accueil | Splash, présentation | Se connecter / Créer un compte, bascule arabe ↔ français |
| Connexion | Téléphone **ou** e-mail | Comptes vérifiés sur l'appareil (PBKDF2), JWT obtenu auprès de l'API quand elle est joignable |
| Profil | Questionnaire en 5 étapes | Âge, sexe, province, commune, situation, niveau, diplôme, formation, objectif, intérêts, compétences, mobilité, accès internet, connexion, disponibilité, présentiel/distanciel |
| Tableau de bord | « Que souhaitez-vous faire aujourd'hui ? » | Assistant, recommandations, opportunités, progression, profil ; bandeau hors connexion |
| Assistant | Conversation | Détection de langue (arabe, darija en lettres latines, français), intention, domaine et contraintes ; ne cite que des offres réelles du catalogue |
| Recommandations | Score de compatibilité | Règles pondérées (25/20/20/15/10/10) et « Pourquoi cette recommandation ? » |
| Opportunité | Détail complet | Organisme, conditions, durée, date limite, compétences visées, modalités, contact, lien officiel, « Je suis intéressée » |
| Mon parcours | Étapes et progression | Profil → Orientation → Opportunité → Inscription → Formation → Certification, badges, documents, historique |
| Centres | Carte hors ligne | Centres et associations, horaires calculés, services, appel et itinéraire |
| Paramètres | | Langue, file de synchronisation, mode hors connexion simulé, consultation et suppression des données |

## Architecture

```
lib/
  core/          network · storage · authentication · localization · connectivity · router · theme
  features/      auth · onboarding · profile · recommendations · opportunities · assistant
                 progress · badges · centers · synchronization · home · settings · shell
  shared/        components · models · constants · utils
backend/         API Flask (JWT, SQLAlchemy, PostgreSQL), mêmes règles de recommandation
assets/data/     catalogue partagé par l'application et l'API
```

Clean Architecture par fonctionnalité, MVVM avec Riverpod, stockage local Hive (chiffré
AES-256 pour les données personnelles, clé dans le coffre du système). Voir
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) pour la synchronisation, la sécurité et les
évolutions prévues (voix, RAG/LLM, amazighe, antennes).

## Tests

```bash
flutter analyze
flutter test                     # 30 tests : moteur, assistant, parcours, synchronisation
cd backend && pytest             # 15 tests : API, synchronisation, parité du moteur
```

Les tests vérifient notamment que Chahd obtient **92 %** pour la « Formation en initiation au
numérique », côté application comme côté serveur, avec les quatre raisons du parcours nominal.

## Photos des offres

Les couvertures sont dessinées par l'application. Pour utiliser de vraies photos, déposer
`assets/images/opportunities/<imageKey>.jpg` (`digital`, `electric`, `sewing`…, voir
`assets/data/opportunities.json`) : elles remplacent automatiquement l'illustration.

## Logo et icônes

Le logo officiel est conservé dans `design/brand/`. L'application n'embarque pas l'image
d'origine mais deux masques blancs transparents (`assets/images/brand/`) qu'elle colore à
l'affichage : blanc sur terracotta (écran de démarrage, accueil), terracotta sur crème
(connexion, inscription). Après une modification du logo :

```bash
flutter test tool/extract_logo_test.dart    # logo d'origine → masques
flutter test tool/generate_icons_test.dart  # masques → icônes Android, iOS, macOS, web, Windows
```
