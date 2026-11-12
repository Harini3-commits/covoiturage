# CoVoit

CoVoit est une plateforme de covoiturage permettant à des conducteurs de publier
des trajets et à des passagers de réserver des places.

## Groupe

- Alexy Traoré
- Chris  Ndjessa
- Chandracoumar Harini

## Base de données choisie

**PostgreSQL**

PostgreSQL a été choisi parce que le projet repose sur des données fortement
relationnelles : utilisateurs, véhicules, trajets, réservations et avis.
Les réservations doivent être fiables afin d’éviter qu’une place soit réservée
deux fois.

## Contenu du dépôt

- `CONCEPTION.md` : règles de gestion, MCD, cardinalités, MLD, ce qui est
  calculé plutôt que recopié, et ce que le schéma ne garantit pas.
- `docs/adr/0001-choix-postgresql.md` : choix et justification de PostgreSQL.
- `modele/` : création de la base, données, requêtes et transaction de réservation.

## Bonus : base de données

Le dossier `modele/` contient :

- `creation.sql` : création des tables PostgreSQL, de leurs contraintes et de
  deux triggers (places du véhicule, avis seulement après le départ).
- `generer_donnees.sql` : génération de données de test (10 utilisateurs,
  5 véhicules, 10 villes, 10 trajets dont 5 passés, des réservations et des
  avis sur les trajets passés).
- `requetes.sql` : requêtes de recherche et de contrôle.
  - recherche de trajets par villes avec les places restantes ;
  - places restantes de chaque trajet et trajets complets ;
  - réservations d'un passager ;
  - avis reçus et note moyenne d'un conducteur ;
  - 5 contrôles de cohérence (C1 à C5) qui doivent renvoyer 0 ligne.
- `reserver_place.sql` : fonction `reserver_place(passager, trajet, nb_places)`.
  Elle verrouille le trajet (`FOR UPDATE`), vérifie les règles (trajet ouvert
  et pas encore parti, conducteur différent du passager, une seule réservation
  par trajet, places suffisantes), puis crée la réservation. Si une règle n'est
  pas respectée, elle renvoie une erreur et rien n'est enregistré.

## Lancer le bonus

1. Créer la base :

```bash
createdb -U postgres covoit
```

2. Créer les tables :

```bash
psql -U postgres -d covoit -f modele/creation.sql
```

3. Générer les données :

```bash
psql -U postgres -d covoit -f modele/generer_donnees.sql
```

4. Lancer les requêtes :

```bash
psql -U postgres -d covoit -f modele/requetes.sql
```

5. Tester la réservation :

```bash
psql -U postgres -d covoit -f modele/reserver_place.sql
```

Avec pgAdmin : créer la base `covoit`, ouvrir son Query Tool, puis coller et
exécuter les 4 fichiers dans le même ordre. Pour rejouer depuis zéro, exécuter
d'abord `DROP SCHEMA public CASCADE; CREATE SCHEMA public;`.

## Réservation sans surréservation (RG7)

Les places restantes ne sont pas stockées : elles sont calculées
(`places_proposees` moins les places des réservations non annulées).
Pour que deux passagers ne prennent pas la dernière place en même temps,
`reserver_place` verrouille d'abord la ligne du trajet avec `FOR UPDATE`.
La seconde réservation attend la fin de la première, puis voit les places
déjà prises.

`reserver_place.sql` contient une démonstration : une réservation réussie, puis
4 réservations refusées (déjà réservé, trop de places, son propre trajet,
trajet inconnu). Les messages « Refusé… » s'affichent dans les messages de
pgAdmin ou dans le terminal.
