# CoVoit

CoVoit est une plateforme de covoiturage permettant à des conducteurs de publier
des trajets et à des passagers de réserver des places.

## Groupe

- Alexy Traoré
- Chris Ndjessa
- Chandracoumar Harini

## Base de données choisie

**PostgreSQL**

PostgreSQL a été choisi parce que le projet repose sur des données fortement
relationnelles : utilisateurs, véhicules, trajets, réservations et avis.

Les réservations doivent être fiables afin d’éviter qu’une place soit réservée
deux fois. PostgreSQL permet de garantir une partie des règles grâce aux clés
primaires, aux clés étrangères, aux contraintes d’unicité et aux contraintes
de vérification.

## Contenu du dépôt

- `CONCEPTION.md` : règles de gestion, MCD, cardinalités, MLD, choix de
  normalisation, données calculées plutôt que recopiées et limites du schéma.
- `docs/adr/0001-choix-postgresql.md` : choix et justification de PostgreSQL,
  comparé à MongoDB et Neo4j.
- `modele/` : création de la base, génération de données, requêtes et
  transaction de réservation.
- `app/` : application bonus utilisant Prisma ORM pour lire et écrire dans
  la base PostgreSQL.

## Modèle de données

Le projet repose sur cinq entités principales :

- `utilisateur`
- `vehicule`
- `trajet`
- `reservation`
- `avis`

Une réservation relie un passager à un trajet. Elle porte les informations
propres à la réservation : nombre de places réservées, statut et date.

Les places restantes ne sont pas stockées dans la base. Elles sont calculées
à partir du nombre de places proposées et du nombre de places déjà réservées
sur les réservations non annulées.

## Bonus SQL

Le dossier `modele/` contient :

- `creation.sql` : création des tables PostgreSQL, de leurs contraintes et
  des triggers nécessaires au projet.
- `generer_donnees.sql` : génération de données de test.
- `requetes.sql` : requêtes de recherche, de contrôle et de statistiques.
- `reserver_place.sql` : fonction de réservation qui vérifie la disponibilité
  des places avant de créer une réservation.

### Lancer le bonus SQL

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

Avec pgAdmin, créez la base `covoit`, ouvrez le Query Tool, puis exécutez les
fichiers SQL dans le même ordre.

Pour recommencer depuis zéro, exécutez d’abord :

```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
```

## Réservation sans surréservation

La règle RG7 impose que le nombre total de places réservées ne dépasse jamais
le nombre de places proposées sur un trajet.

Les places restantes sont calculées ainsi :

```text
places restantes = places proposées - places réservées non annulées
```

La fonction `reserver_place` verrouille d’abord la ligne du trajet avec
`FOR UPDATE`. Ainsi, si deux passagers essaient de réserver la dernière place
en même temps, le second attend la fin de la première réservation.

Si les places demandées dépassent les places restantes, la réservation est
refusée et rien n’est enregistré dans la base.

## Bonus : application avec Prisma

Le dossier `app/` contient une petite application utilisant Prisma ORM pour
interroger la base PostgreSQL.

L’application permet de :

- afficher les trajets disponibles ;
- réserver des places sur un trajet ;
- afficher les réservations d’un passager ;
- afficher les avis d’un conducteur.

La fonction `reserverPlace` vérifie la disponibilité des places avant de créer
une réservation. Elle empêche ainsi de réserver plus de places que le nombre
de places proposées.

### Installer l’application

Depuis la racine du projet :

```bash
cd app
npm install
```

### Générer le client Prisma

```bash
npx prisma generate
```

### Lancer l’application

```bash
npx tsx index.js
```

L’application affiche les utilisateurs enregistrés dans la base.

### Tester une réservation

Dans le fichier `index.js`, la fonction suivante est appelée :

```js
await reserverPlace(3, 1, 1);
```

Elle signifie :

- le passager numéro 3 ;
- réserve sur le trajet numéro 1 ;
- une place.

Si la réservation réussit, le terminal affiche la réservation créée.

Si le passager a déjà réservé ce trajet, si le trajet est complet ou si le
passager est le conducteur, une erreur est affichée et aucune réservation
n’est créée.

## Configuration de la base

L’application Prisma lit la variable `DATABASE_URL` depuis le fichier `.env`.

Créez un fichier `.env` dans le dossier `app/` :

```env
DATABASE_URL="postgresql://postgres:MOT_DE_PASSE@localhost:5432/covoit"
```

Remplacez `MOT_DE_PASSE` par le mot de passe PostgreSQL de votre ordinateur.

Ne partagez jamais votre mot de passe PostgreSQL et ne poussez pas le fichier
`.env` sur GitHub.

## Sécurité

Le fichier `.gitignore` empêche le dépôt d’inclure :

- `node_modules`
- `.env`
- les fichiers générés par Prisma

Les contraintes `CHECK` restent gérées directement par PostgreSQL. Prisma ne
les expose pas entièrement dans son client, mais elles continuent de protéger
la base lors des insertions SQL.