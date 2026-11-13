require('dotenv').config();

const { reserverPlace } = require('./app.js');

async function main() {
  const resultat = await reserverPlace(3, 1, 1);

  console.log(resultat);
}

main()
  .catch(console.error)
  .finally(async () => {
    const { PrismaClient } = require('./prisma/generated/prisma/client');
    const prisma = new PrismaClient();
    await prisma.$disconnect();
  });