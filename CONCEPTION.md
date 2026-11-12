# CoVoit

CoVoit est une plateforme de covoiturage permettant à des conducteurs de publier
des trajets et à des passagers de réserver des places.

**Base choisie :** PostgreSQL

## Règles de gestion

### RG1 — Utilisateur
Chaque utilisateur possède exactement un identifiant unique, un nom, un prénom,
une adresse e-mail unique et un mot de passe.
L’adresse e-mail et le mot de passe sont obligatoires.

### RG2 — Rôle d’un utilisateur
Un utilisateur peut être conducteur, passager, ou les deux.
Un utilisateur peut ne posséder aucun véhicule.
Un utilisateur qui publie un trajet doit posséder au moins un véhicule.

### RG3 — Véhicule
Chaque véhicule possède exactement un identifiant unique, une immatriculation
unique, une marque, un modèle et un nombre de places.
Chaque véhicule appartient à exactement un utilisateur.
Un utilisateur peut posséder zéro, un ou plusieurs véhicules.

### RG4 — Publication d’un trajet
Chaque trajet est publié par exactement un conducteur.
Chaque trajet utilise exactement un véhicule appartenant à ce conducteur.
Un conducteur peut publier zéro, un ou plusieurs trajets.

### RG5 — Informations d’un trajet
Chaque trajet possède exactement une ville de départ, une ville d’arrivée,
une date de départ, une heure de départ, un prix par place et un nombre
de places proposées.
Le prix par place est toujours supérieur ou égal à zéro.
Le nombre de places proposées est toujours supérieur à zéro.

### RG6 — Réservation d’un trajet
Un passager peut réserver une ou plusieurs places sur un trajet.
Un passager peut effectuer au plus une réservation pour un même trajet.
Un trajet peut recevoir zéro, une ou plusieurs réservations.
Le prix d’une place est fixé au moment de la réservation : si le conducteur
change son prix ensuite, la réservation garde le prix qu’elle avait.

### RG7 — Disponibilité des places
Le nombre total de places réservées sur un trajet ne dépasse jamais le nombre
de places proposées par le conducteur.
Une place ne peut pas être réservée deux fois.

### RG8 — Statut d’une réservation
Chaque réservation possède exactement un statut parmi :
« en attente », « confirmée », « annulée » ou « terminée ».
Une réservation annulée libère les places qu’elle occupait.

### RG9 — Avis sur un conducteur
Après un trajet, un passager peut laisser au plus un avis sur le conducteur.
Chaque avis possède exactement une note comprise entre 1 et 5,
un commentaire facultatif et une date.
Un avis concerne exactement un trajet.
Un avis est toujours rattaché à exactement une réservation ; une réservation
donne lieu à zéro ou un avis. On ne laisse pas d’avis sur une réservation annulée.

### RG10 — Auteur et destinataire d’un avis
Chaque avis est écrit par exactement un utilisateur.
Chaque avis concerne exactement un utilisateur destinataire.
Un utilisateur ne peut pas laisser un avis sur lui-même.

### RG11 — Annulation d’une réservation
Un passager peut annuler une réservation tant que le trajet n’a pas commencé.
Lorsqu’une réservation est annulée, les places qu’elle occupait redeviennent
disponibles pour d’autres passagers.

### RG12 — Villes
Chaque ville possède exactement un nom et un code postal ; le couple
(nom, code postal) est unique.
Une ville peut être la ville de départ de zéro, un ou plusieurs trajets, et
la ville d’arrivée de zéro, un ou plusieurs trajets.
La ville d’arrivée d’un trajet est toujours différente de sa ville de départ.

### Les questions qu’on s’est posées

| Question | Réponse retenue |
|---|---|
| Conducteur et passager : deux entités, ou une seule ? | **Une seule**, `UTILISATEUR` (RG2). La même personne conduit un jour et voyage le lendemain : le rôle vient de l’association. |
| Le trajet est-il relié au conducteur, ou au véhicule ? | **Au véhicule** dans le MCD (« Effectuer ») : le conducteur est son propriétaire (RG4). Dans le MLD, on recopie le conducteur exprès, et le schéma garantit que la copie est juste (voir plus bas). |
| Une ville est-elle un simple texte dans le trajet ? | **Non, c’est une entité** (RG12). Sinon « Lyon », « lyon » et « LYON » seraient trois villes, et la recherche par ville ne serait pas fiable. |
| Un passager peut-il réserver deux fois le même trajet ? | **Non** (RG6) : une seule réservation, avec un nombre de places. S’il annule puis revient, on réactive la même réservation. |
| Le prix payé suit-il le prix du trajet ? | **Non** (RG6) : il est recopié dans la réservation au moment où elle est faite. |
| Supprime-t-on une réservation annulée ? | **Non** (RG8, RG11) : elle passe à l’état « annulée », libère ses places, et reste dans l’historique. |
| À quoi un avis est-il rattaché : au trajet, ou à la réservation ? | **À la réservation** (RG9). C’est elle qui prouve que l’auteur a voyagé, et « au plus un avis par réservation » se traduit par un simple `UNIQUE`. |
| Une ville peut-elle n’avoir aucun trajet ? | **Oui** (RG12) : le référentiel des villes est chargé à l’avance. |
| Gère-t-on le paiement ? | **Non, hors périmètre.** On garde seulement le prix unitaire de la réservation. |

## MCD

![MCD du covoiturage](docs/MCD%20Covoiturage.png)

### Les associations et leurs cardinalités

| Association | Côté A (card.) | Côté B (card.) | Règle |
|---|---|---|---|
| Posséder | UTILISATEUR (0,n) | VEHICULE (1,1) | RG2, RG3 |
| Effectuer | VEHICULE (0,n) | TRAJET (1,1) | RG4 |
| Partir de | VILLE (0,n) | TRAJET (1,1) | RG5, RG12 |
| Arriver à | VILLE (0,n) | TRAJET (1,1) | RG5, RG12 |
| Faire | UTILISATEUR (0,n) | RESERVATION (1,1) | RG6 |
| Concerner | TRAJET (0,n) | RESERVATION (1,1) | RG6 |
| Recevoir | RESERVATION (0,1) | AVIS (1,1) | RG9 |

`RESERVATION` est l’**association porteuse de données** entre un passager et un trajet. Elle porte le nombre de places, le prix unitaire, le statut et la date. On l’a transformée en entité pour deux raisons : un avis s’y rattache (« Recevoir »), et son statut évolue dans le temps. Son identifiant métier est le couple (passager, trajet), ce qui traduit RG6.

Les identifiants : un `id` technique partout. Les identifiants métier, quand ils existent, sont l’e-mail (RG1), l’immatriculation (RG3) et le couple (nom, code postal) pour une ville (RG12). L’identifiant d’`AVIS` est `id` (et non `note`).

## MLD dans PostgreSQL

### Le schéma relationnel

<u>Souligné</u> = clé primaire, `#` = clé étrangère.

- **utilisateur** (<u>id</u>, nom, prenom, email UNIQUE, mot_de_passe, telephone, date_inscription)
- **vehicule** (<u>id</u>, #proprietaire_id, immatriculation UNIQUE, marque, modele, couleur, nb_places)
- **ville** (<u>id</u>, nom, code_postal) — UNIQUE (nom, code_postal)
- **trajet** (<u>id</u>, #vehicule_id, #conducteur_id, #ville_depart_id, #ville_arrivee_id, date_depart, heure_depart, prix_place, places_proposees, statut)
- **reservation** (<u>id</u>, #passager_id, #trajet_id, nb_places_reservees, prix_unitaire, statut, date_reservation) — UNIQUE (passager_id, trajet_id)
- **avis** (<u>id</u>, #reservation_id UNIQUE, note, commentaire, date_avis)

Le script de création est [`modele/creation.sql`](modele/creation.sql).

### Chaque association, et où elle est rangée

| Association | Card. | Rangement | Pourquoi (règle de passage) |
|---|---|---|---|
| Posséder | 0,n – 1,1 | Clé étrangère `vehicule.proprietaire_id` → `utilisateur`, **NOT NULL** | Pour une association 0,n – 1,1, la clé étrangère va du côté 1,1. NOT NULL traduit le « exactement un » de RG3. |
| Effectuer | 0,n – 1,1 | Clé étrangère `trajet.vehicule_id`, NOT NULL. On y ajoute la copie `conducteur_id`, tenue juste par une clé **composite** `(vehicule_id, conducteur_id)` → `vehicule(id, proprietaire_id)` | Même règle pour `vehicule_id`. La clé composite garantit RG4 dans le schéma : impossible de publier un trajet avec la voiture d’un autre. |
| Partir de / Arriver à | 0,n – 1,1 (×2) | Deux clés étrangères NOT NULL vers `ville` (`ville_depart_id`, `ville_arrivee_id`), et `CHECK (ville_depart_id <> ville_arrivee_id)` | Deux associations entre les mêmes entités donnent deux clés étrangères avec un nom de rôle. Le CHECK traduit RG12. |
| Faire | 0,n – 1,1 | Clé étrangère `reservation.passager_id`, NOT NULL | La clé étrangère va du côté 1,1. |
| Concerner | 0,n – 1,1 | Clé étrangère `reservation.trajet_id`, NOT NULL, et `UNIQUE (passager_id, trajet_id)` | Même règle. Le UNIQUE traduit le « au plus une réservation par trajet » de RG6. |
| Recevoir | 0,1 – 1,1 | Clé étrangère `avis.reservation_id`, **NOT NULL UNIQUE** | La clé étrangère va du côté 1,1 (l’avis). Le UNIQUE traduit le 0,1 côté réservation : au plus un avis par réservation (RG9). On ne la met pas dans `reservation`, où elle serait le plus souvent vide. |

**Les données portées par l’association** (nombre de places, prix unitaire, statut, date) vont dans `reservation` : elles ne dépendent ni du passager seul, ni du trajet seul.

**Ce qui est déduit sans être stocké :**
- l’auteur d’un avis, qui est le passager de sa réservation ;
- le destinataire d’un avis, qui est le conducteur du trajet.

RG10 (« jamais d’avis sur soi-même ») en découle : un passager n’est jamais le conducteur de son trajet.

**Les écarts entre le MCD et le MLD :**
- `départ_le` est rangé en `date_depart` + `heure_depart`, comme le formule RG5 ;
- `mot_de_passe` vient de RG1 : il n’est pas dessiné sur le MCD ;
- `conducteur_id` est une copie voulue (voir ci-dessous).

### Ce qu’on recopie exprès, et ce qu’on calcule

| Donnée | Décision | Qui tient la copie à jour |
|---|---|---|
| `trajet.conducteur_id` | **Recopié** depuis le propriétaire du véhicule. Il fige le conducteur du trajet dans l’historique, et les recherches « mes trajets » se font sans jointure. | **Le schéma** : la clé étrangère composite refuse toute valeur fausse. Conséquence : un véhicule qui a déjà servi ne peut pas changer de propriétaire (il est refusé), et le nouveau propriétaire le redéclare. |
| `reservation.prix_unitaire` | **Recopié** depuis `trajet.prix_place` au moment de la réservation (RG6). | **Personne, et c’est voulu** : c’est une photographie. `reserver_place` l’écrit une fois, et elle ne suit pas les changements de prix ultérieurs. |
| Places restantes d’un trajet | **Calculées** : `places_proposees − SUM(nb_places_reservees)` sur les réservations non annulées. | Pas de copie, donc rien à synchroniser. Un compteur stocké serait la valeur la plus disputée de la base : toutes les réservations concurrentes l’écriraient. |
| Note moyenne d’un conducteur | **Calculée** sur `avis` (requête 6). | Pas de copie. À revoir seulement si on triait les recherches par note sur de gros volumes. |

## Ce que le schéma ne garantit pas

Les contraintes (clés étrangères, UNIQUE, CHECK, NOT NULL) regardent **une ligne** ou une paire de clés. Tout ce qui dépend d’un total, d’une autre table ou de l’heure courante est garanti ailleurs. Chaque règle a aussi un contrôle dans [`modele/requetes.sql`](modele/requetes.sql) (C1 à C5), qui doit renvoyer 0 ligne.

| Règle | Pourquoi le schéma ne suffit pas | Où on la garantit |
|---|---|---|
| **RG7 : pas de surréservation** | C’est une somme sur plusieurs réservations, comparée à une colonne du trajet. Deux réservations simultanées pourraient voir chacune « 1 place restante ». | **Transaction** dans la fonction `reserver_place` ([`modele/reserver_place.sql`](modele/reserver_place.sql)). Elle verrouille la ligne du trajet (`SELECT … FOR UPDATE`), puis compte les places. La seconde réservation attend la première, puis voit ses places. Cela suppose que toute réservation passe par cette fonction : en production, le compte de l’application n’aurait que le droit `EXECUTE` sur elle, sans `INSERT` sur `reservation`. Contrôle : C1. |
| RG6 : le prix unitaire = le prix du trajet au moment de la réservation | Dépend d’une autre table, à un instant donné. | **`reserver_place`**, qui recopie `prix_place`. |
| RG10 : un conducteur ne réserve pas son propre trajet | Compare `reservation.passager_id` à `trajet.conducteur_id`, dans une autre table. | **`reserver_place`**. Contrôle : C2. |
| RG11 : pas de réservation après le départ | Dépend de l’heure courante, or un CHECK doit être déterministe. | **`reserver_place`**. Contrôle : C4. |
| RG11 : on n’annule plus après le départ | Même raison. | **Code applicatif** : le bonus n’a pas de fonction d’annulation. |
| RG5 : places proposées ≤ places du véhicule | Compare deux tables. | **Trigger** `trg_trajet_places`. Contrôle : C5. |
| RG9 : un avis seulement après le départ, et jamais sur une réservation annulée | Dépend de l’heure courante et du statut de la réservation. | **Trigger** `trg_avis`. Contrôle : C3. |
| RG8 : les transitions de statut (« annulée » ne redevient « confirmée » que par une nouvelle réservation ; « terminée » après le trajet) | Un CHECK voit la nouvelle valeur, pas l’ancienne. | **Code applicatif**, et `reserver_place` pour la réactivation. |
| RG1 : le mot de passe est stocké haché | Le schéma voit seulement un texte. | **Code applicatif**. |

Ce que le schéma garantit seul :
- l’unicité de l’e-mail, de l’immatriculation et de la ville ;
- le véhicule qui appartient au conducteur (RG4) ;
- le départ différent de l’arrivée ;
- une réservation par passager et par trajet ;
- un avis par réservation ;
- les valeurs de statut, les notes de 1 à 5, et les prix et places positifs.
