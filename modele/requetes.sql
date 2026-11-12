-- Requêtes pour CoVoit
-- Lancer : psql -U postgres -d covoit -f modele/requetes.sql
-- Une réservation occupe des places tant qu'elle n'est pas annulée (RG8).

-- 1. Rechercher les trajets d'une ville à une autre, avec les places restantes
--    (RG5, RG12 : un trajet a une ville de départ, une ville d'arrivée, une date et un prix)
SELECT t.id,
       vd.nom AS ville_depart,
       va.nom AS ville_arrivee,
       t.date_depart,
       t.heure_depart,
       t.prix_place,
       t.places_proposees - COALESCE(SUM(r.nb_places_reservees), 0) AS places_restantes
FROM trajet t
JOIN ville vd ON vd.id = t.ville_depart_id
JOIN ville va ON va.id = t.ville_arrivee_id
LEFT JOIN reservation r
       ON r.trajet_id = t.id AND r.statut <> 'annulee'
WHERE vd.nom = 'Marseille'
  AND va.nom = 'Toulouse'
  AND t.date_depart >= CURRENT_DATE
  AND t.statut = 'publie'
GROUP BY t.id, vd.nom, va.nom
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
SELECT t.id, vd.nom AS ville_depart, va.nom AS ville_arrivee, t.date_depart
FROM trajet t
JOIN ville vd ON vd.id = t.ville_depart_id
JOIN ville va ON va.id = t.ville_arrivee_id
LEFT JOIN reservation r
       ON r.trajet_id = t.id AND r.statut <> 'annulee'
GROUP BY t.id, vd.nom, va.nom
HAVING t.places_proposees - COALESCE(SUM(r.nb_places_reservees), 0) = 0;

-- 4. Réservations d'un passager, avec le trajet concerné (RG6)
--    Le total utilise le prix recopié à la réservation, pas le prix actuel du trajet.
SELECT r.id AS reservation,
       r.statut,
       r.nb_places_reservees,
       vd.nom AS ville_depart,
       va.nom AS ville_arrivee,
       t.date_depart,
       r.prix_unitaire * r.nb_places_reservees AS total
FROM reservation r
JOIN trajet t ON t.id = r.trajet_id
JOIN ville vd ON vd.id = t.ville_depart_id
JOIN ville va ON va.id = t.ville_arrivee_id
WHERE r.passager_id = 2
ORDER BY t.date_depart;

-- 5. Avis reçus par un conducteur (RG9, RG10)
--    L'auteur est le passager de la réservation, le destinataire le conducteur du trajet.
SELECT a.date_avis,
       a.note,
       a.commentaire,
       u.prenom || ' ' || u.nom AS auteur
FROM avis a
JOIN reservation r ON r.id = a.reservation_id
JOIN trajet t      ON t.id = r.trajet_id
JOIN utilisateur u ON u.id = r.passager_id
WHERE t.conducteur_id = 2
ORDER BY a.date_avis DESC;

-- 6. Note moyenne de chaque conducteur : calculée à partir des avis, jamais recopiée
SELECT u.id,
       u.prenom || ' ' || u.nom AS conducteur,
       ROUND(AVG(a.note), 2)    AS note_moyenne,
       COUNT(a.id)              AS nb_avis
FROM avis a
JOIN reservation r ON r.id = a.reservation_id
JOIN trajet t      ON t.id = r.trajet_id
JOIN utilisateur u ON u.id = t.conducteur_id
GROUP BY u.id
ORDER BY note_moyenne DESC, nb_avis DESC;

-- 7. Montant réservé par conducteur (réservations non annulées, au prix payé)
SELECT t.conducteur_id,
       SUM(r.prix_unitaire * r.nb_places_reservees) AS total
FROM trajet t
JOIN reservation r ON r.trajet_id = t.id AND r.statut <> 'annulee'
GROUP BY t.conducteur_id
ORDER BY total DESC;

-- ----------------------------------------------------------------
-- Contrôles de cohérence : ce que le schéma ne garantit pas.
-- Chaque requête doit renvoyer 0 ligne. Voir CONCEPTION.md pour
-- l'endroit où chaque règle est garantie.
-- ----------------------------------------------------------------

-- C1. Trajet surréservé (RG7) — garanti par reserver_place (verrou FOR UPDATE)
SELECT t.id, t.places_proposees, SUM(r.nb_places_reservees) AS places_reservees
FROM trajet t
JOIN reservation r ON r.trajet_id = t.id AND r.statut <> 'annulee'
GROUP BY t.id
HAVING SUM(r.nb_places_reservees) > t.places_proposees;

-- C2. Conducteur qui réserve son propre trajet (RG10) — garanti par reserver_place
SELECT r.id AS reservation, r.passager_id, r.trajet_id
FROM reservation r
JOIN trajet t ON t.id = r.trajet_id
WHERE r.passager_id = t.conducteur_id;

-- C3. Avis sur une réservation annulée ou avant le départ (RG9) — garanti par trg_avis
SELECT a.id, r.statut, t.date_depart
FROM avis a
JOIN reservation r ON r.id = a.reservation_id
JOIN trajet t      ON t.id = r.trajet_id
WHERE r.statut = 'annulee'
   OR a.date_avis < t.date_depart;

-- C4. Réservation faite après le départ du trajet (RG11) — garanti par reserver_place
SELECT r.id AS reservation, r.date_reservation, t.date_depart, t.heure_depart
FROM reservation r
JOIN trajet t ON t.id = r.trajet_id
WHERE r.date_reservation > t.date_depart + t.heure_depart;

-- C5. Trajet qui propose plus de places que le véhicule n'en a (RG5) — garanti par trg_trajet_places
SELECT t.id AS trajet, t.places_proposees, v.nb_places
FROM trajet t
JOIN vehicule v ON v.id = t.vehicule_id
WHERE t.places_proposees > v.nb_places;
