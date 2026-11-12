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
INSERT INTO vehicule (proprietaire_id, immatriculation, marque, modele, nb_places)
SELECT
    ((i - 1) % 10) + 1,
    'AB-' || LPAD(i::TEXT, 3, '0') || '-CD',
    'Marque' || i,
    'Modele' || i,
    4
FROM generate_series(1, 5) AS i;

-- 3. Générer 10 trajets
INSERT INTO trajet (
    conducteur_id,
    vehicule_id,
    ville_depart,
    ville_arrivee,
    date_depart,
    heure_depart,
    prix_place,
    places_proposees
)
SELECT
    ((i - 1) % 5) + 1,
    ((i - 1) % 5) + 1,
    'Ville Depart ' || i,
    'Ville Arrivee ' || i,
    CURRENT_DATE + i,
    '08:00',
    20 + i,
    4
FROM generate_series(1, 10) AS i;

-- 4. Générer 15 réservations
INSERT INTO reservation (passager_id, trajet_id, nb_places_reservees, statut)
SELECT
    ((i - 1) % 10) + 1,
    ((i - 1) % 10) + 1,
    1,
    'confirmee'
FROM generate_series(1, 15) AS i
ON CONFLICT DO NOTHING;

-- 5. Générer 10 avis
INSERT INTO avis (auteur_id, destinataire_id, trajet_id, note, commentaire)
SELECT
    ((i - 1) % 10) + 1,
    ((i - 1) % 5) + 1,
    ((i - 1) % 10) + 1,
    1 + (i % 5),
    'Bon trajet.'
FROM generate_series(1, 10) AS i
ON CONFLICT DO NOTHING;