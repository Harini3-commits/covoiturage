-- Requêtes pour CoVoit
-- Lancer : psql -U postgres -d covoit -f modele/requetes.sql
-- Une réservation occupe des places tant qu'elle n'est pas annulée (RG8).

-- 1. Rechercher les trajets d'une ville à une autre, avec les places restantes
--    (RG5 : un trajet a une ville de départ, une ville d'arrivée, une date et un prix)
SELECT t.id,
       t.ville_depart,
       t.ville_arrivee,
       t.date_depart,
       t.heure_depart,
       t.prix_place,
       t.places_proposees - COALESCE(SUM(r.nb_places_reservees), 0) AS places_restantes
FROM trajet t
LEFT JOIN reservation r
       ON r.trajet_id = t.id AND r.statut <> 'annulee'
WHERE t.ville_depart  = 'Ville Depart 3'
  AND t.ville_arrivee = 'Ville Arrivee 3'
  AND t.date_depart  >= CURRENT_DATE
GROUP BY t.id
HAVING t.places_proposees - COALESCE(SUM(r.nb_places_reservees), 0) > 0
ORDER BY t.date_depart, t.heure_depart;

-- 2. Places restantes de chaque trajet (RG7 : on ne dépasse jamais les places proposées)
SELECT t.id AS trajet,
       t.places_proposees,
       COALESCE(SUM(r.nb_places_reservees), 0) AS places_reservees,
       t.places_proposees - COALESCE(SUM(r.nb_places_reservees), 0) AS places_restantes
FROM trajet t
LEFT JOIN reservation r
       ON r.trajet_id = t.id AND r.statut <> 'annulee'
GROUP BY t.id
ORDER BY t.id;

-- 3. Trajets complets (plus aucune place disponible)
SELECT t.id, t.ville_depart, t.ville_arrivee, t.date_depart
FROM trajet t
LEFT JOIN reservation r
       ON r.trajet_id = t.id AND r.statut <> 'annulee'
GROUP BY t.id
HAVING t.places_proposees - COALESCE(SUM(r.nb_places_reservees), 0) = 0;

-- 4. Réservations d'un passager, avec le trajet concerné (RG6)
SELECT r.id AS reservation,
       r.statut,
       r.nb_places_reservees,
       t.ville_depart,
       t.ville_arrivee,
       t.date_depart,
       t.prix_place * r.nb_places_reservees AS total
FROM reservation r
JOIN trajet t ON t.id = r.trajet_id
WHERE r.passager_id = 2
ORDER BY t.date_depart;

-- 5. Avis reçus par un conducteur (RG9, RG10)
SELECT a.date_avis,
       a.note,
       a.commentaire,
       u.prenom || ' ' || u.nom AS auteur
FROM avis a
JOIN utilisateur u ON u.id = a.auteur_id
WHERE a.destinataire_id = 2
ORDER BY a.date_avis DESC;

-- 6. Note moyenne de chaque conducteur : calculée à partir des avis, jamais recopiée
SELECT u.id,
       u.prenom || ' ' || u.nom AS conducteur,
       ROUND(AVG(a.note), 2)    AS note_moyenne,
       COUNT(a.id)              AS nb_avis
FROM utilisateur u
JOIN avis a ON a.destinataire_id = u.id
GROUP BY u.id
ORDER BY note_moyenne DESC, nb_avis DESC;

-- 7. Chiffre d'affaires potentiel par conducteur (réservations non annulées)
SELECT t.conducteur_id,
       SUM(t.prix_place * r.nb_places_reservees) AS total
FROM trajet t
JOIN reservation r ON r.trajet_id = t.id AND r.statut <> 'annulee'
GROUP BY t.conducteur_id
ORDER BY total DESC;

-- ----------------------------------------------------------------
-- Contrôles de cohérence : ce que le schéma ne garantit pas.
-- Chaque requête doit renvoyer 0 ligne.
-- ----------------------------------------------------------------

-- C1. Trajet surréservé (RG7)
SELECT t.id, t.places_proposees, SUM(r.nb_places_reservees) AS places_reservees
FROM trajet t
JOIN reservation r ON r.trajet_id = t.id AND r.statut <> 'annulee'
GROUP BY t.id
HAVING SUM(r.nb_places_reservees) > t.places_proposees;

-- C2. Conducteur qui réserve son propre trajet (conséquence de RG10)
SELECT r.id AS reservation, r.passager_id, r.trajet_id
FROM reservation r
JOIN trajet t ON t.id = r.trajet_id
WHERE r.passager_id = t.conducteur_id;

-- C3. Avis laissé sur soi-même (RG10)
SELECT id, auteur_id, destinataire_id
FROM avis
WHERE auteur_id = destinataire_id;

-- C4. Trajet dont le véhicule n'appartient pas au conducteur (RG4)
SELECT t.id AS trajet, t.conducteur_id, v.proprietaire_id
FROM trajet t
JOIN vehicule v ON v.id = t.vehicule_id
WHERE v.proprietaire_id <> t.conducteur_id;

-- C5. Trajet qui propose plus de places que le véhicule n'en a
SELECT t.id AS trajet, t.places_proposees, v.nb_places
FROM trajet t
JOIN vehicule v ON v.id = t.vehicule_id
WHERE t.places_proposees > v.nb_places;
