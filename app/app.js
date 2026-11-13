require('dotenv').config();

const { PrismaClient } = require('./prisma/generated/prisma/client');

const prisma = new PrismaClient();

// Afficher les trajets disponibles
async function afficherTrajets() {
  const trajets = await prisma.trajet.findMany({
    include: {
      utilisateur: true,
      vehicule: true,
      reservation: true
    }
  });

  return trajets;
}

// Réserver des places
async function reserverPlace(passagerId, trajetId, nbPlaces) {
  const trajet = await prisma.trajet.findUnique({
    where: {
      id: trajetId
    },
    include: {
      reservation: true
    }
  });

  if (!trajet) {
    throw new Error('Trajet introuvable.');
  }

  const placesReservees = trajet.reservation
    .filter(reservation => reservation.statut !== 'annulee')
    .reduce((total, reservation) => total + reservation.nb_places_reservees, 0);

  const placesRestantes = trajet.places_proposees - placesReservees;

  if (nbPlaces > placesRestantes) {
    throw new Error('Il ne reste pas assez de places disponibles.');
  }

  const reservation = await prisma.reservation.create({
    data: {
      passager_id: passagerId,
      trajet_id: trajetId,
      nb_places_reservees: nbPlaces,
      statut: 'confirmee'
    }
  });

  return reservation;
}

// Afficher les réservations d’un passager
async function reservationsPassager(passagerId) {
  const reservations = await prisma.reservation.findMany({
    where: {
      passager_id: passagerId
    },
    include: {
      trajet: true
    }
  });

  return reservations;
}

// Afficher les avis d’un conducteur
async function avisConducteur(conducteurId) {
  const avis = await prisma.avis.findMany({
    where: {
      trajet: {
        conducteur_id: conducteurId
      }
    },
    include: {
      trajet: true
    }
  });

  return avis;
}

module.exports = {
  afficherTrajets,
  reserverPlace,
  reservationsPassager,
  avisConducteur
};