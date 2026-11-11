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

### RG10 — Auteur et destinataire d’un avis
Chaque avis est écrit par exactement un utilisateur.
Chaque avis concerne exactement un utilisateur destinataire.
Un utilisateur ne peut pas laisser un avis sur lui-même.

### RG11 — Annulation d’une réservation
Un passager peut annuler une réservation tant que le trajet n’a pas commencé.
Lorsqu’une réservation est annulée, les places qu’elle occupait redeviennent
disponibles pour d’autres passagers.
   ## MCD

   ![MCD du covoiturage](docs/MCD%20Covoiturage.png)
