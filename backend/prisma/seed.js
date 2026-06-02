import "dotenv/config";
import { PrismaClient } from "@prisma/client/index.js";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";
import bcrypt from "bcrypt";

const dbUrl = new URL(process.env.DATABASE_URL);
const dbName = dbUrl.pathname.replace(/^\//, "");

const adapter = new PrismaMariaDb({
  host: dbUrl.hostname,
  port: parseInt(dbUrl.port, 10) || 3306,
  user: dbUrl.username,
  password: decodeURIComponent(dbUrl.password),
  database: dbName,
  connectionLimit: 10,
});

const prisma = new PrismaClient({ adapter });

async function main() {
  console.log("🌱 Creating 50 School Admins...");

  const hashedPassword = await bcrypt.hash("Admin123!", 10);

  for (let i = 1; i <= 50; i++) {
    try {
      await prisma.user.create({
        data: {
          fullName: `Admin ${i}`,
          email: `admin${i}@school.com`,
          phone: `0911${String(i).padStart(6, "0")}`,
          password: hashedPassword,

          role: "SCHOOL_ADMIN",
          accountStatus: "ACTIVE",

          emailVerified: true,
          phoneVerified: true,
        },
      });

      console.log(`✅ Created Admin ${i}`);
    } catch (error) {
      console.error(`❌ Failed Admin ${i}:`, error.message);
    }
  }

  console.log("🏁 Finished creating school admins");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });