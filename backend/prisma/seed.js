import "dotenv/config";
import { PrismaClient } from "@prisma/client/index.js";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";
import { faker } from "@faker-js/faker";

// 1. Safely break down your environment connection URL
const dbUrl = new URL(process.env.DATABASE_URL);
const dbName = dbUrl.pathname.replace(/^\//, "");

// 2. Instantiate the PrismaMariaDb driver adapter natively
const adapter = new PrismaMariaDb({
  host: dbUrl.hostname,
  port: parseInt(dbUrl.port, 10) || 3306,
  user: dbUrl.username,
  password: decodeURIComponent(dbUrl.password),
  database: dbName,
  connectionLimit: 10,
});

// 3. Supply the native adapter to your Prisma Client instance
const prisma = new PrismaClient({ adapter });

const schools = [
  {
    schoolName: "Addis Future Academy",
    curriculum: "INTERNATIONAL",
    tuitionFee: 120000,
    rating: 4.8,
    schoolLevel: "SECONDARY",
    schoolType: "PRIVATE",
    latitude: 9.03,
    longitude: 38.74,
    passingRate: 96,
    nationalExamScore: 92,
    achievementScore: 95,
  },
  {
    schoolName: "Unity Public School",
    curriculum: "LOCAL",
    tuitionFee: 15000,
    rating: 3.9,
    schoolLevel: "PRIMARY",
    schoolType: "GOVERNMENT",
    latitude: 9.05,
    longitude: 38.7,
    passingRate: 70,
    nationalExamScore: 68,
    achievementScore: 40,
  },
  {
    schoolName: "Bright Path Academy",
    curriculum: "INTERNATIONAL",
    tuitionFee: 85000,
    rating: 4.5,
    schoolLevel: "PRIMARY",
    schoolType: "PRIVATE",
    latitude: 9.01,
    longitude: 38.76,
    passingRate: 90,
    nationalExamScore: 88,
    achievementScore: 80,
  },
  {
    schoolName: "Selam Secondary School",
    curriculum: "LOCAL",
    tuitionFee: 25000,
    rating: 4.1,
    schoolLevel: "SECONDARY",
    schoolType: "GOVERNMENT",
    latitude: 9.0,
    longitude: 38.73,
    passingRate: 76,
    nationalExamScore: 72,
    achievementScore: 50,
  },
  {
    schoolName: "Ethio STEM School",
    curriculum: "INTERNATIONAL",
    tuitionFee: 140000,
    rating: 4.9,
    schoolLevel: "SECONDARY",
    schoolType: "PRIVATE",
    latitude: 9.08,
    longitude: 38.78,
    passingRate: 99,
    nationalExamScore: 97,
    achievementScore: 99,
  },
  {
    schoolName: "Hope Elementary",
    curriculum: "LOCAL",
    tuitionFee: 12000,
    rating: 3.7,
    schoolLevel: "PRIMARY",
    schoolType: "GOVERNMENT",
    latitude: 9.02,
    longitude: 38.71,
    passingRate: 65,
    nationalExamScore: 60,
    achievementScore: 30,
  },
  {
    schoolName: "Nile International School",
    curriculum: "INTERNATIONAL",
    tuitionFee: 110000,
    rating: 4.6,
    schoolLevel: "SECONDARY",
    schoolType: "PRIVATE",
    latitude: 9.06,
    longitude: 38.79,
    passingRate: 93,
    nationalExamScore: 91,
    achievementScore: 88,
  },
  {
    schoolName: "Community Growth School",
    curriculum: "LOCAL",
    tuitionFee: 18000,
    rating: 4.0,
    schoolLevel: "PRIMARY",
    schoolType: "CHURCH",
    latitude: 9.04,
    longitude: 38.72,
    passingRate: 74,
    nationalExamScore: 70,
    achievementScore: 45,
  },
  {
    schoolName: "Alpha Excellence Academy",
    curriculum: "INTERNATIONAL",
    tuitionFee: 95000,
    rating: 4.7,
    schoolLevel: "SECONDARY",
    schoolType: "PRIVATE",
    latitude: 9.07,
    longitude: 38.75,
    passingRate: 95,
    nationalExamScore: 94,
    achievementScore: 91,
  },
  {
    schoolName: "Sunrise Preparatory",
    curriculum: "LOCAL",
    tuitionFee: 22000,
    rating: 4.2,
    schoolLevel: "PRIMARY",
    schoolType: "PRIVATE",
    latitude: 9.03,
    longitude: 38.77,
    passingRate: 79,
    nationalExamScore: 75,
    achievementScore: 58,
  },
];

async function main() {
  console.log("🌱 Starting recommendation test seeding...");

  for (const schoolData of schools) {
    try {
      // Wrapping with transaction logic like your previous working seeder script
      await prisma.$transaction(async (tx) => {
        const admin = await tx.user.create({
          data: {
            fullName: faker.person.fullName(),
            email: faker.internet.email(),
            password: "hashed_password",
            role: "SCHOOL_ADMIN",
            accountStatus: "ACTIVE", // Included to match previous working schema properties
          },
        });

        const school = await tx.school.create({
          data: {
            adminId: admin.id,
            schoolName: schoolData.schoolName,
            contactEmail: faker.internet.email(),
            contactPhone: "+251911000000",
            curriculum: schoolData.curriculum,
            tuitionFee: schoolData.tuitionFee,
            facilities: "Library, Science Lab, Football Field, ICT Lab",
            verificationStatus: "VERIFIED",
            latitude: schoolData.latitude,
            longitude: schoolData.longitude,
            rating: schoolData.rating,
            reviewCount: faker.number.int({ min: 5, max: 200 }),
            schoolLevel: schoolData.schoolLevel,
            schoolType: schoolData.schoolType,
            subCity: "BOLE",
            totalAchievementScore: schoolData.achievementScore,
          },
        });

        await tx.schoolDemographics.create({
          data: {
            schoolId: school.id,
            academicYear: 2025,
            totalStudents: faker.number.int({ min: 300, max: 3000 }),
            girlsCount: faker.number.int({ min: 100, max: 1500 }),
            boysCount: faker.number.int({ min: 100, max: 1500 }),
            passingRate: schoolData.passingRate,
            nationalExamScore: schoolData.nationalExamScore,
          },
        });

        await tx.achievement.create({
          data: {
            schoolId: school.id,
            title: "National Science Competition",
            year: 2025,
            tier: "GOLD",
            score: schoolData.achievementScore,
            status: "APPROVED",
          },
        });

        await tx.staffBreakdown.create({
          data: {
            schoolId: school.id,
            educationLevel: "DEGREE",
            count: faker.number.int({ min: 10, max: 60 }),
          },
        });

        console.log(`✅ Seeded ${school.schoolName}`);
      });
    } catch (error) {
      console.error(
        `❌ Error seeding row for ${schoolData.schoolName}:`,
        error.message,
      );
    }
  }

  console.log("🏁 Seeding completed.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
