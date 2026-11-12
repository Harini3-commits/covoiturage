-- Génération de données de test pour CoVoit

-- 1. Générer 10 utilisateurs
INSERT INTO utilisateur (nom, prenom, email, mot_de_passe, telephone)
SELECT
    'Nom' || i,
    'Prenom' || i,
    'utilisateur' || i || '@example.com',
    'mdp123',
    '06' || LPAD(i::TEXT, 8, '0')
FROM generate_series(1, 10) AS i;

-- 2. Générer 5 véhicules
INSERT INTO vehicule (proprietaire_id, immatriculation, marque, modele, couleur, nb_places)
SELECT
    ((i - 1) % 10) + 1,
    'AB-' || LPAD(i::TEXT, 3, '0') || '-CD',
    'Marque' || i,
    'Modele' || i,
    (ARRAY['blanc', 'noir', 'gris', 'bleu', 'rouge'])[i],
    4
FROM generate_series(1, 5) AS i;

-- 3. Les villes (RG12)
INSERT INTO ville (nom, code_postal) VALUES
    ('Paris', '75001'), ('Lyon', '69001'), ('Marseille', '13001'),
    ('Toulouse', '31000'), ('Nice', '06000'), ('Nantes', '44000'),
    ('Strasbourg', '67000'), ('Montpellier', '34000'), ('Bordeaux', '33000'),
    ('Lille', '59000');

-- 4. Générer 10 trajets
-- Les trajets 1 à 5 sont à venir, les trajets 6 à 10 ont déjà eu lieu
-- (il faut des trajets passés pour pouvoir laisser des avis, RG9).
-- Le conducteur est le propriétaire du véhicule (RG4, clé composite).
INSERT INTO trajet (
    vehicule_id,
    conducteur_id,
    ville_depart_id,
    ville_arrivee_id,
    date_depart,
    heure_depart,
    prix_place,
    places_proposees,
    statut
)
SELECT
    v.id,
    v.proprietaire_id,
    ((i - 1) % 10) + 1,
    (i % 10) + 1,
    CASE WHEN i <= 5 THEN CURRENT_DATE + i ELSE CURRENT_DATE - (i - 5) END,
    '08:00',
    20 + i,
    4,
    CASE WHEN i <= 5 THEN 'publie' ELSE 'termine' END
FROM generate_series(1, 10) AS i
JOIN vehicule v ON v.id = ((i - 1) % 5) + 1
ORDER BY i;                -- le trajet n° i reçoit l'id i (utilisé par la démo)

-- 5. Générer les réservations
-- (le passager est toujours différent du conducteur du trajet)
-- prix_unitaire recopie le prix du trajet au moment de la réservation (RG6).
-- Chaque réservation est faite 2 jours avant le départ.
INSERT INTO reservation (passager_id, trajet_id, nb_places_reservees, prix_unitaire, statut, date_reservation)
SELECT
    (i % 10) + 1,
    t.id,
    1,
    t.prix_place,
    CASE WHEN t.statut = 'termine' THEN 'terminee' ELSE 'confirmee' END,
    t.date_depart + t.heure_depart - INTERVAL '2 days'
FROM generate_series(1, 15) AS i
JOIN trajet t ON t.id = ((i - 1) % 10) + 1
ORDER BY i
ON CONFLICT DO NOTHING;

-- 6. Générer les avis
-- Un avis par réservation d'un trajet passé (RG9) : l'auteur est le passager
-- de la réservation, le destinataire le conducteur du trajet (RG10).
INSERT INTO avis (reservation_id, note, commentaire, date_avis)
SELECT
    r.id,
    1 + (r.id % 5),
    'Bon trajet.',
    t.date_depart + 1
FROM reservation r
JOIN trajet t ON t.id = r.trajet_id
WHERE r.statut = 'terminee';
