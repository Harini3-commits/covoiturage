-- Transaction de réservation d'une place pour CoVoit
-- Lancer : psql -U postgres -d covoit -f modele/reserver_place.sql
--
-- Principe : on verrouille la ligne du trajet (FOR UPDATE) avant de compter les
-- places prises. Deux passagers qui réservent en même temps sur le même trajet
-- passent donc l'un après l'autre : le second voit les places déjà prises par le
-- premier. Une place ne peut pas être réservée deux fois (RG7).
-- Toute erreur annule la transaction : rien n'est enregistré à moitié.

CREATE OR REPLACE FUNCTION reserver_place(
    p_passager INTEGER,
    p_trajet   INTEGER,
    p_nb       INTEGER
) RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
    v_trajet   trajet%ROWTYPE;
    v_prises   INTEGER;
    v_existante reservation%ROWTYPE;
    v_id       INTEGER;
    v_a_deja   BOOLEAN;
BEGIN
    IF p_nb IS NULL OR p_nb < 1 THEN
        RAISE EXCEPTION 'Il faut réserver au moins une place';
    END IF;

    -- 1. Verrouiller le trajet : les autres réservations du même trajet attendent ici
    SELECT * INTO v_trajet FROM trajet WHERE id = p_trajet FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trajet % introuvable', p_trajet;
    END IF;

    PERFORM 1 FROM utilisateur WHERE id = p_passager;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Passager % introuvable', p_passager;
    END IF;

    -- 2. Règles métier
    IF v_trajet.statut IN ('annule', 'termine') THEN
        RAISE EXCEPTION 'Ce trajet n''accepte plus de réservations (statut : %)', v_trajet.statut;
    END IF;

    IF (v_trajet.date_depart + v_trajet.heure_depart) <= now() THEN
        RAISE EXCEPTION 'Le trajet a déjà commencé';
    END IF;

    IF p_passager = v_trajet.conducteur_id THEN
        RAISE EXCEPTION 'Un conducteur ne peut pas réserver son propre trajet';
    END IF;

    -- 3. Une seule réservation par passager et par trajet (RG6)
    SELECT * INTO v_existante
    FROM reservation
    WHERE passager_id = p_passager AND trajet_id = p_trajet;

    v_a_deja := FOUND;

    IF v_a_deja AND v_existante.statut <> 'annulee' THEN
        RAISE EXCEPTION 'Ce passager a déjà une réservation pour ce trajet';
    END IF;

    -- 4. Places disponibles (RG7) : les réservations annulées ne comptent pas (RG8)
    SELECT COALESCE(SUM(nb_places_reservees), 0) INTO v_prises
    FROM reservation
    WHERE trajet_id = p_trajet AND statut <> 'annulee';

    IF v_prises + p_nb > v_trajet.places_proposees THEN
        RAISE EXCEPTION 'Plus assez de places : % restante(s), % demandée(s)',
            v_trajet.places_proposees - v_prises, p_nb;
    END IF;

    -- 5. Enregistrer la réservation
    --    prix_unitaire recopie le prix du trajet à cet instant (RG6) : si le
    --    conducteur change son prix ensuite, la réservation garde le sien.
    IF v_a_deja THEN
        -- le passager avait annulé : on réactive sa réservation (une seule par trajet),
        -- au prix du moment, puisque c'est une nouvelle réservation
        UPDATE reservation
        SET nb_places_reservees = p_nb, prix_unitaire = v_trajet.prix_place,
            statut = 'en_attente', date_reservation = now()
        WHERE id = v_existante.id
        RETURNING id INTO v_id;
    ELSE
        INSERT INTO reservation (passager_id, trajet_id, nb_places_reservees, prix_unitaire, statut)
        VALUES (p_passager, p_trajet, p_nb, v_trajet.prix_place, 'en_attente')
        RETURNING id INTO v_id;
    END IF;

    RETURN v_id;
END;
$$;

-- ----------------------------------------------------------------
-- Démonstration
-- ----------------------------------------------------------------

-- Cas nominal : le passager 10 réserve 2 places sur le trajet 2
BEGIN;
SELECT reserver_place(10, 2, 2) AS reservation_creee;
COMMIT;

-- Places restantes du trajet 2 après la réservation
SELECT t.places_proposees - COALESCE(SUM(r.nb_places_reservees), 0) AS places_restantes
FROM trajet t
LEFT JOIN reservation r ON r.trajet_id = t.id AND r.statut <> 'annulee'
WHERE t.id = 2
GROUP BY t.id;

-- Cas refusés : chacun doit afficher un message d'erreur, sans rien enregistrer
DO $$
BEGIN
    BEGIN PERFORM reserver_place(10, 2, 1);
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Refusé (déjà réservé) : %', SQLERRM; END;

    BEGIN PERFORM reserver_place(7, 2, 10);
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Refusé (trop de places) : %', SQLERRM; END;

    BEGIN PERFORM reserver_place(2, 2, 1);
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Refusé (son propre trajet) : %', SQLERRM; END;

    BEGIN PERFORM reserver_place(7, 999, 1);
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Refusé (trajet inconnu) : %', SQLERRM; END;
END $$;
