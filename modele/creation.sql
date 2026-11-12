-- Création de la base CoVoit
-- Traduit le MLD de CONCEPTION.md (section « MLD dans PostgreSQL »).
-- Les RGn renvoient aux règles de gestion de CONCEPTION.md.

-- RG1
CREATE TABLE utilisateur (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(80) NOT NULL,
    prenom VARCHAR(80) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,              -- identifiant métier
    mot_de_passe VARCHAR(255) NOT NULL,
    telephone VARCHAR(20),
    date_inscription DATE NOT NULL DEFAULT CURRENT_DATE
);

-- RG3 : Posséder (UTILISATEUR 0,n — VEHICULE 1,1)
CREATE TABLE vehicule (
    id SERIAL PRIMARY KEY,
    proprietaire_id INTEGER NOT NULL REFERENCES utilisateur(id),
    immatriculation VARCHAR(15) NOT NULL UNIQUE,     -- identifiant métier
    marque VARCHAR(50) NOT NULL,
    modele VARCHAR(50) NOT NULL,
    couleur VARCHAR(30),
    nb_places INTEGER NOT NULL CHECK (nb_places > 0),
    -- cible de la clé étrangère composite de trajet (RG4)
    UNIQUE (id, proprietaire_id)
);

-- RG12
CREATE TABLE ville (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    code_postal CHAR(5) NOT NULL,
    UNIQUE (nom, code_postal)                        -- identifiant métier
);

-- RG4, RG5, RG12 : Effectuer, Partir de, Arriver à
CREATE TABLE trajet (
    id SERIAL PRIMARY KEY,
    vehicule_id INTEGER NOT NULL,
    -- copie voulue : le conducteur se déduit du véhicule (MCD), on le recopie
    -- pour l'historique et les recherches ; la clé composite la tient juste.
    conducteur_id INTEGER NOT NULL REFERENCES utilisateur(id),
    ville_depart_id INTEGER NOT NULL REFERENCES ville(id),
    ville_arrivee_id INTEGER NOT NULL REFERENCES ville(id),
    date_depart DATE NOT NULL,
    heure_depart TIME NOT NULL,
    prix_place NUMERIC(6,2) NOT NULL CHECK (prix_place >= 0),
    places_proposees INTEGER NOT NULL CHECK (places_proposees > 0),
    statut VARCHAR(20) NOT NULL DEFAULT 'publie'
        CHECK (statut IN ('publie', 'annule', 'termine')),
    -- RG4 : le véhicule appartient au conducteur, garanti par le schéma
    FOREIGN KEY (vehicule_id, conducteur_id) REFERENCES vehicule(id, proprietaire_id),
    -- RG12 : départ et arrivée différents
    CHECK (ville_depart_id <> ville_arrivee_id)
);

-- RG6, RG8 : Faire (UTILISATEUR 0,n — RESERVATION 1,1)
--            Concerner (RESERVATION 1,1 — TRAJET 0,n)
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    passager_id INTEGER NOT NULL REFERENCES utilisateur(id),
    trajet_id INTEGER NOT NULL REFERENCES trajet(id),
    nb_places_reservees INTEGER NOT NULL CHECK (nb_places_reservees > 0),
    -- copie voulue (RG6) : le prix d'une place au moment de la réservation
    prix_unitaire NUMERIC(6,2) NOT NULL CHECK (prix_unitaire >= 0),
    statut VARCHAR(20) NOT NULL DEFAULT 'en_attente'
        CHECK (statut IN ('en_attente', 'confirmee', 'annulee', 'terminee')),
    date_reservation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (passager_id, trajet_id)                  -- RG6 : au plus une par trajet
);

-- RG9, RG10 : Recevoir (RESERVATION 0,1 — AVIS 1,1)
-- L'auteur est le passager de la réservation, le destinataire le conducteur
-- du trajet : on les retrouve par jointure, sans les recopier.
CREATE TABLE avis (
    id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL UNIQUE           -- UNIQUE : au plus un avis (0,1)
        REFERENCES reservation(id),
    note INTEGER NOT NULL CHECK (note BETWEEN 1 AND 5),
    commentaire TEXT,
    date_avis DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Index des lectures fréquentes : la recherche de trajets, les clés étrangères
CREATE INDEX idx_trajet_recherche ON trajet (ville_depart_id, ville_arrivee_id, date_depart);
CREATE INDEX idx_reservation_trajet ON reservation (trajet_id);

-- ----------------------------------------------------------------
-- Ce que les contraintes ne voient pas : les triggers
-- (CONCEPTION.md, « Ce que le schéma ne garantit pas »)
-- ----------------------------------------------------------------

-- RG5 : un trajet ne propose pas plus de places que son véhicule n'en a
CREATE FUNCTION verifier_places_trajet() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_places INTEGER;
BEGIN
    SELECT nb_places INTO v_places FROM vehicule WHERE id = NEW.vehicule_id;
    IF NEW.places_proposees > v_places THEN
        RAISE EXCEPTION 'RG5 : % places proposées pour un véhicule de % places',
            NEW.places_proposees, v_places;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_trajet_places
    BEFORE INSERT OR UPDATE OF places_proposees, vehicule_id ON trajet
    FOR EACH ROW EXECUTE FUNCTION verifier_places_trajet();

-- RG9 : un avis seulement après le départ, et pas sur une réservation annulée
CREATE FUNCTION verifier_avis() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_statut VARCHAR(20);
    v_depart TIMESTAMP;
BEGIN
    SELECT r.statut, t.date_depart + t.heure_depart INTO v_statut, v_depart
    FROM reservation r JOIN trajet t ON t.id = r.trajet_id
    WHERE r.id = NEW.reservation_id;

    IF v_statut = 'annulee' THEN
        RAISE EXCEPTION 'RG9 : pas d''avis sur une réservation annulée';
    END IF;
    IF v_depart > now() THEN
        RAISE EXCEPTION 'RG9 : pas d''avis avant le départ du trajet';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_avis
    BEFORE INSERT OR UPDATE OF reservation_id ON avis
    FOR EACH ROW EXECUTE FUNCTION verifier_avis();
