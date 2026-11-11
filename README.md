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