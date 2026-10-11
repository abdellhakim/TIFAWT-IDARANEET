# Démonstration — parcours nominal

Déroulé de 5 à 7 minutes, aligné sur la fiche « Parcours nominal TIFAWT ».
Persona : **Chahd**, 21 ans, Bac, Taroudant, cherche une formation, se déplace peu.

## Avant de commencer

- Installer l'APK (`flutter build apk --release`) ou lancer `flutter run`.
- Choisir la langue sur l'écran d'accueil (bouton **ع / FR** en haut).
- Si l'appareil a déjà servi : **Paramètres → Réinitialiser le compte de démonstration**.
- Pour la coupure réseau : mode avion sur le téléphone, ou, si ce n'est pas possible
  (émulateur projeté, Wi-Fi partagé…), **Paramètres → Simuler le mode hors connexion**.

## Déroulé

| # | Étape de la fiche | Geste | Ce que le jury voit |
|---|---|---|---|
| 0 | Accueil | — | « TIFAWT — Votre passerelle vers les opportunités », boutons *Se connecter* / *Créer un compte* |
| 1 | Connexion | *Se connecter* → toucher la carte **Compte de démonstration** → *Se connecter* | Identifiant téléphone ou e-mail ; le compte fictif est déjà créé |
| 2 | Profil | Faire défiler les 5 étapes avec *Suivant* → *Enregistrer mon profil* | Questionnaire pré-rempli (province Taroudant, Bac, objectif formation, mobilité limitée…). Badge « Profil complété » |
| 3 | Tableau de bord | — | « Bonjour Chahd », « Que souhaitez-vous faire aujourd'hui ? » et les 5 actions |
| 4 | Assistant | *Mon assistant* → taper : *Je cherche une formation en informatique mais je n'ai pas beaucoup de moyens pour me déplacer.* | Ligne « Compris : Formation · Numérique · Près de chez vous », réponse « D'après votre profil, je peux vous proposer des formations … accessibles dans votre zone et adaptées à votre niveau », 2 offres avec leur score |
| 5 | Recommandations | *Voir mes opportunités adaptées* | **Formation en initiation au numérique** — Lieu Taroudant · Niveau Bac · Type Formation · Durée 3 mois · **92 %** · « Pourquoi cette recommandation ? » (objectif de formation, centres d'intérêt, niveau, zone). Le bouton ⚙ montre les 6 critères pondérés |
| 6 | Détail | *Voir l'opportunité* | Organisme, présentation, localisation, conditions d'accès, durée, date limite, compétences visées, modalités, contact et lien officiel |
| 7 | Ajout au parcours | *Je suis intéressée* | « Opportunité ajoutée à votre parcours — Statut : Intéressée », badge « Première opportunité sélectionnée » |
| 8 | Ma progression | Lien *Mon parcours* (ou onglet Parcours) | ✓ Profil, ✓ Orientation, ✓ Opportunité sélectionnée, ● Inscription, ○ Formation, ○ Certification — **50 %** |
| 9 | Hors connexion | Couper le réseau → *Mettre à jour le statut* → **Inscription effectuée** | Bandeau « Hors connexion — Vos données seront synchronisées… », message « Action enregistrée hors connexion — Elle sera synchronisée dès que la connexion sera disponible », compteur d'actions en attente |
| 10 | Retour du réseau | Rétablir le réseau | « Connexion rétablie » → « Synchronisation en cours… » → « Synchronisation terminée » |
| 11 | Fin | Onglet *Parcours* | Profil ✓, Orientation ✓, Opportunité ✓, Inscription ✓, ligne **Synchronisation ✓** avec l'heure |

## Points d'attention

- **Progression finale.** La fiche indique 50 % à l'étape 11, mais à ce stade l'inscription
  est effectuée : l'application affiche honnêtement **4 étapes sur 6 (67 %)**. Pour retrouver
  exactement 50 % en fin de démonstration, faire à l'étape 9 une autre action hors connexion
  (enregistrer une offre ♥, cocher un document « prête ») plutôt que le changement de statut.
- **Horaires des centres.** L'état « Ouvert / Fermé » est calculé selon l'heure réelle.
- **Serveur.** Sans `TIFAWT_API_URL`, la synchronisation passe par un serveur simulé (indiqué
  dans Paramètres). Avec l'API lancée, les opérations arrivent dans la table `sync_logs`.

## Questions probables du jury

- *Comment le score est-il calculé ?* — Règles pondérées et explicables : 25 % objectif,
  20 % niveau, 20 % intérêts, 15 % compétences, 10 % proximité, 10 % contraintes
  (internet, mobilité, modalité, âge, disponibilité). Même code côté téléphone et côté serveur.
- *Et l'IA ?* — L'assistant du MVP est à base de règles : il fonctionne hors ligne et ne peut
  pas inventer d'offre. L'API prévoit des fournisseurs LLM interchangeables (OpenAI ou modèle
  souverain) qui reçoivent uniquement le contexte récupéré ; la clé reste côté serveur.
- *Darija et amazighe ?* — Interface arabe/français ; l'assistant comprend le français, l'arabe
  et la darija écrite en lettres latines (« bghit khdma »). L'amazighe est une évolution, à valider.
- *Les données personnelles ?* — Chiffrées sur le téléphone, consultables et supprimables dans
  les paramètres, données fictives pour la démonstration ; prise en compte de la loi 09-08 et
  de la CNDP, analyse de conformité prévue avant tout lancement.
