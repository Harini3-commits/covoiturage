-- Création de la base CoVoit

CREATE TABLE utilisateur (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(80) NOT NULL,
    prenom VARCHAR(80) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL,
    telephone VARCHAR(20),
    date_inscription DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE vehicule (
    id SERIAL PRIMARY KEY,
    proprietaire_id INTEGER NOT NULL REFERENCES utilisateur(id),
    immatriculation VARCHAR(15) NOT NULL UNIQUE,
    marque VARCHAR(50) NOT NULL,
    modele VARCHAR(50) NOT NULL,
    nb_places INTEGER NOT NULL CHECK (nb_places > 0)
);

CREATE TABLE trajet (
    id SERIAL PRIMARY KEY,
    conducteur_id INTEGER NOT NULL REFERENCES utilisateur(id),
    vehicule_id INTEGER NOT NULL REFERENCES vehicule(id),
    ville_depart VARCHAR(100) NOT NULL,
    ville_arrivee VARCHAR(100) NOT NULL,
    date_depart DATE NOT NULL,
    heure_depart TIME NOT NULL,
    prix_place NUMERIC(6,2) NOT NULL CHECK (prix_place >= 0),
    places_proposees INTEGER NOT NULL CHECK (places_proposees > 0),
    statut VARCHAR(20) NOT NULL DEFAULT 'publie'
);

CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    passager_id INTEGER NOT NULL REFERENCES utilisateur(id),
    trajet_id INTEGER NOT NULL REFERENCES trajet(id),
    nb_places_reservees INTEGER NOT NULL CHECK (nb_places_reservees > 0),
    statut VARCHAR(20) NOT NULL DEFAULT 'en_attente',
    date_reservation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (passager_id, trajet_id)
);

CREATE TABLE avis (
    id SERIAL PRIMARY KEY,
    auteur_id INTEGER NOT NULL REFERENCES utilisateur(id),
    destinataire_id INTEGER NOT NULL REFERENCES utilisateur(id),
    trajet_id INTEGER NOT NULL REFERENCES trajet(id),
    note INTEGER NOT NULL CHECK (note BETWEEN 1 AND 5),
    commentaire TEXT,
    date_avis DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE (auteur_id, trajet_id)
);