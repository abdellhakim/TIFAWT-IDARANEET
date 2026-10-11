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


