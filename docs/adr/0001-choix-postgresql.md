# ADR 0001 — Choix de PostgreSQL pour CoVoit

## Statut

Accepté

## Contexte

CoVoit est une plateforme de covoiturage. Des conducteurs publient des trajets,
des passagers réservent des places, et des passagers peuvent laisser un avis
sur le conducteur après un trajet.

Le système doit gérer des données fortement liées entre elles :

- un utilisateur peut posséder plusieurs véhicules ;
- un conducteur publie des trajets ;
- un véhicule est utilisé pour un trajet ;
- un passager réserve une ou plusieurs places sur un trajet ;
- un passager peut laisser un avis sur un conducteur après un trajet.

La règle la plus importante est la disponibilité des places : le nombre total
de places réservées sur un trajet ne doit jamais dépasser le nombre de places
proposées. Une place ne doit donc pas pouvoir être vendue deux fois.

Les données doivent rester cohérentes : une réservation doit toujours
correspondre à un utilisateur et à un trajet existants.

## Options considérées

### Option 1 — PostgreSQL

PostgreSQL est une base de données relationnelle. Les données sont organisées
dans des tables reliées par des clés primaires et des clés étrangères.

Elle permet notamment :

- de créer des tables pour les utilisateurs, véhicules, trajets, réservations
  et avis ;
- de garantir qu’une réservation pointe vers un utilisateur et un trajet
  existants grâce aux clés étrangères ;
- d’empêcher un passager de créer deux réservations pour le même trajet grâce
  à une contrainte d’unicité ;
- de vérifier que le prix d’une place est positif ou nul, et que le nombre de
  places est supérieur à zéro grâce à des contraintes `CHECK` ;
- d’utiliser des transactions pour gérer les réservations de manière cohérente.

### Option 2 — MongoDB

MongoDB est une base de données orientée documents. Les données sont stockées
sous forme de documents JSON, ce qui peut être pratique pour des objets dont
la structure varie beaucoup.

Pour CoVoit, MongoDB pourrait convenir pour stocker des profils utilisateurs
ou des annonces de trajets avec des informations facultatives.

Cependant, les réservations dépendent fortement les unes des autres :
une réservation est liée à un utilisateur, à un trajet et à un nombre de places
disponibles. Avec MongoDB, il faudrait souvent dupliquer certaines informations
ou gérer la cohérence dans le code de l’application.

### Option 3 — Neo4j

Neo4j est une base de données orientée graphe. Elle est particulièrement
adaptée aux relations complexes entre des entités, par exemple les amis d’amis,
les recommandations ou les liens entre utilisateurs.

Pour CoVoit, Neo4j pourrait être utile si l’application proposait des
recommandations avancées, comme suggérer des trajets en fonction des trajets
des amis ou des trajets similaires.

Cependant, le cœur du sujet n’est pas la recommandation. Il s’agit surtout de
gérer des trajets, des véhicules, des réservations et des avis de manière
fiable. Ces données sont naturellement relationnelles.

## Décision

Nous utilisons PostgreSQL comme base de données principale pour CoVoit.

PostgreSQL est retenu parce que les données du projet sont structurées,
fortement reliées entre elles et soumises à des règles de cohérence importantes,
notamment la disponibilité des places.

## Justification

Les entités principales de CoVoit sont :

- `UTILISATEUR`
- `VEHICULE`
- `TRAJET`
- `RESERVATION`
- `AVIS`

Ces entités ont des relations stables :

- un véhicule appartient à exactement un utilisateur ;
- un trajet est publié par exactement un conducteur ;
- un trajet utilise exactement un véhicule ;
- une réservation concerne exactement un passager et un trajet ;
- un avis est écrit par exactement un utilisateur et concerne exactement un
  autre utilisateur.

PostgreSQL permet de traduire ces règles dans la base grâce aux clés primaires,
aux clés étrangères, aux contraintes d’unicité et aux contraintes de
vérification.

La réservation est l’association la plus importante du modèle. Elle porte des
données : le nombre de places réservées, le statut de la réservation et la date
de réservation. Elle devient donc une table `reservation` dans PostgreSQL.

La règle RG7 impose que le total des places réservées ne dépasse pas le nombre
de places proposées. Cette règle ne peut pas être garantie uniquement par une
contrainte simple, car elle dépend de plusieurs réservations. Elle sera donc
vérifiée lors de la création d’une réservation, dans une transaction.

## Normalisation

Nous choisissons une base normalisée.

Chaque information est enregistrée une seule fois :

- les informations d’un utilisateur sont dans la table `utilisateur` ;
- les informations d’un véhicule sont dans la table `vehicule` ;
- les informations d’un trajet sont dans la table `trajet` ;
- les informations d’une réservation sont dans la table `reservation` ;
- les informations d’un avis sont dans la table `avis` ;
- les villes sont dans la table `ville`, et un trajet y fait référence.

Les places restantes et la note moyenne d’un conducteur ne sont pas stockées :
elles sont calculées. Un compteur de places stocké serait écrit par toutes les
réservations concurrentes, et il pourrait diverger.

Deux copies sont faites exprès, et chacune a son gardien :

- `reservation.prix_unitaire` recopie le prix du trajet au moment de la
  réservation. C’est une photographie : elle ne doit pas suivre un changement
  de prix ultérieur. `reserver_place` l’écrit une fois, puis personne ne la
  modifie.
- `trajet.conducteur_id` recopie le propriétaire du véhicule. Une clé
  étrangère composite `(vehicule_id, conducteur_id)` vers
  `vehicule(id, proprietaire_id)` empêche cette copie d’être fausse. En
  contrepartie, un véhicule qui a déjà servi ne peut plus changer de
  propriétaire.

Le détail est dans `CONCEPTION.md`, section « Ce qu’on recopie exprès ».

Nous ne dupliquons pas le nom du conducteur, la marque du véhicule ou la ville
de départ dans la table `reservation`. Ces informations sont récupérées grâce
aux clés étrangères.

Cela évite les incohérences : si un utilisateur modifie son nom, il n’est pas
nécessaire de modifier ce nom dans toutes les réservations.

## Conséquences positives

- Les données sont cohérentes grâce aux clés étrangères.
- Les réservations sont mieux contrôlées grâce aux contraintes d’unicité.
- Les requêtes SQL permettent facilement de rechercher des trajets, compter
  les places restantes et afficher les avis.
- Les transactions permettent de vérifier la disponibilité des places avant
  de confirmer une réservation.
- Le modèle est clair et facile à faire évoluer si l’application ajoute
  ensuite des paiements, des messages ou des trajets récurrents.

## Conséquences négatives

- PostgreSQL est moins naturel que MongoDB pour stocker des documents avec une
  structure très variable.
- PostgreSQL est moins adapté que Neo4j pour des recommandations complexes
  fondées sur de nombreux liens entre utilisateurs.
- La vérification de la disponibilité des places demande une transaction ou une
  vérification dans le code : une simple contrainte `CHECK` ne suffit pas.
- Si l’application devenait très grande et recevait un très grand nombre
  d’écritures simultanées, il faudrait étudier des solutions complémentaires,
  par exemple une base clé-valeur pour des données très temporaires.

## Ce qui nous ferait revoir la décision

Nous pourrions revoir ce choix si CoVoit devenait principalement un réseau
social de covoiturage, avec des recommandations complexes entre utilisateurs,
des amis, des trajets similaires et des suggestions personnalisées.

Dans ce cas, Neo4j pourrait devenir intéressant pour gérer les relations entre
utilisateurs et recommander des trajets.

Nous pourrions aussi ajouter MongoDB si nous souhaitions stocker des contenus
très flexibles, comme des annonces riches ou des profils personnalisés.
Cependant, PostgreSQL resterait la base principale pour les réservations,
les trajets et les avis.