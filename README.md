# CoVoit

CoVoit est une plateforme de covoiturage permettant à des conducteurs de publier
des trajets et à des passagers de réserver des places.

## Groupe

- [Alexy Traoré]
- [Chris Aurel Ndjessa]
- [Chandracoumar Harini]

## Base de données choisie

**PostgreSQL**

PostgreSQL a été choisi parce que le projet repose sur des données fortement
relationnelles : utilisateurs, véhicules, trajets, réservations et avis.
Les réservations doivent être fiables afin d’éviter qu’une place soit réservée
deux fois.

## Contenu du dépôt

- `CONCEPTION.md` : règles de gestion, MCD, MLD et limites du schéma.
- `docs/adr/0001-choix-postgresql.md` : choix et justification de PostgreSQL.
- `modele/` : création de la base, données et requêtes.

## Bonus : base de données

Le dossier `modele/` contient :

- `creation.sql` : création des tables PostgreSQL.
- `generer_donnees.sql` : génération de données de test.
- `requetes.sql` : requêtes pour rechercher des trajets, calculer les places
  restantes et afficher les avis.
- `reserver_place.sql` : transaction qui vérifie la disponibilité des places
  avant de créer une réservation.

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