/** @type {import('jest').Config} */
const config = {
  // Use Node's native ESM support via experimental-vm-modules (set in npm test script)
  testEnvironment: "node",
  // Only look for tests in src/tests
  testMatch: ["**/src/tests/**/*.test.js"],
  // Allow imports from node_modules that ship ESM (e.g. axios, supertest)
  transformIgnorePatterns: [],
  // No transform needed — project is native ESM
  transform: {},
  // Give each test file its own module registry so monkey-patches don't leak
  resetModules: false,
  // Generous timeout for DB operations
  testTimeout: 30000,
  // Run test files sequentially to avoid DB race conditions
  maxWorkers: 1,
};

export default config;
