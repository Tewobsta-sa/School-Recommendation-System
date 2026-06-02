# Fidel Guide

Web platform that helps Ethiopian parents discover, compare and get personalized school recommendations, backed by MoE verification, moderated reviews, and a forum for community Q&A.

## Tech Stack

- **Backend**: Node.js + Express 5 (ESM) + Prisma 7 (MariaDB adapter) + JWT auth
- **Frontend**: Flutter (Web, Android, iOS) with custom design system
- **Database**: MariaDB 10.6+ / MySQL 8+
- **Authentication**: JWT with email verification
- **Maps**: OpenStreetMap (no API key required)
- **Recommendation Engine** - [Recommendation Engine Github Link](https://github.com/Tewobsta-sa/Recommendation_Engine)
## Features

### Core Functionality
- **School Discovery**: Search, filter, and browse schools with detailed information
- **Personalized Recommendations**: AI-powered school recommendations based on parent preferences
- **School Comparison**: Side-by-side comparison of 2-5 schools with detailed metrics
- **Reviews & Ratings**: Parent reviews with moderation and category-based tags
- **Follow System**: Subscribe to schools for targeted announcements
- **Announcements**: School and Ministry announcements with targeted delivery
- **Forum**: Community Q&A for parent discussions
- **School Verification**: Document submission and MoE approval workflow
- **Analytics**: School and Ministry-level analytics dashboards

### User Roles
- **Parents**: Browse schools, get recommendations, write reviews, participate in forum
- **School Admins**: Manage school information, post announcements, view analytics
- **MoE Officers**: Review verification requests, post ministry announcements, access analytics
- **Moderators**: Review and moderate community content

## Getting Started

```bash
# 1. Clone + enter
git clone <this-repo>
cd School-Recommendation-System

# 2. Backend setup
cd backend
npm install

# 3. Configure environment
cp .env.example .env
# Edit .env to point at your local MariaDB and set JWT_SECRET

# 4. Run Prisma migrations
npx prisma migrate dev

# 5. Start the backend server
npm run dev
```

The backend server will start on `http://localhost:5050`

## Frontend Setup

```bash
# 1. Navigate to frontend
cd frontend

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure API URL (optional for local development)
# For local development, the default http://localhost:5050 is already configured
# For different environments, use:
# flutter run --dart-define=API_BASE_URL=http://your-api-url:5050

# 4. Run the app
# Web
flutter run -d chrome

# Android
flutter run

# iOS
flutter run
```

## Environment Variables

See [`backend/.env.example`](backend/.env.example) and [`frontend/.env.example`](frontend/.env.example) for the full list.

### Required Backend Variables
- `JWT_SECRET` - Signing key for access tokens
- `DATABASE_HOST` - MariaDB host
- `DATABASE_USER` - MariaDB user
- `DATABASE_PASSWORD` - MariaDB password
- `DATABASE_NAME` - MariaDB database name
- `DATABASE_URL` - Full connection string

### Optional Backend Variables
- `PORT` (default `5050`)
- `NODE_ENV` (default `development`)
- `LOG_LEVEL` (default `debug`)
- `JWT_EXPIRES_IN` (default `1d`)
- `APP_URL` - Base URL for email links (default `http://localhost:5050`)
- `SMTP_URL` - SMTP endpoint for real email delivery
- `MAIL_FROM` - Sender address (default `no-reply@fidelguide.local`)
- `ML_SERVICE_URL` - ML service URL for recommendations
- `UPLOAD_DIR` - File upload directory
- `UPLOAD_MAX_SIZE_BYTES` - Max file size (default 10MB)

### Frontend Variables
- `API_BASE_URL` - Backend API URL (default `http://localhost:5050`)

## Common Scripts

### Backend (from `backend/`)
```bash
npm run dev                  # Start Express with watch mode
npm test                     # Run Jest + Supertest suites
npx prisma migrate dev       # Create new migration
npx prisma migrate deploy    # Apply pending migrations
npx prisma studio            # Open Prisma data browser
```

### Frontend (from `frontend/`)
```bash
flutter pub get              # Install dependencies
flutter run                 # Run app (detects connected device)
flutter build web            # Build for web
flutter build apk            # Build Android APK
flutter build ios            # Build iOS app
flutter analyze             # Analyze code for issues
```

## Project Layout

```
backend/
  prisma/                 Prisma schema + migrations
  src/
    app.js                Express app (middleware stack + routes)
    server.js             Process entry (reads .env, starts listener)
    config/               db.js, logger.js, uploads.js
    middlewares/          auth, role, validation, error handling
    routes/               One router per subsystem (REST)
    controllers/          Thin layer, delegates to services
    services/             Business rules, data access via Prisma
    schemas/              Zod request-validation schemas
    utils/                Error classes, helpers
    tests/                Jest + Supertest integration tests

frontend/
  lib/
    core/                 Design system, theme, typography, router
    features/             Feature modules (auth, schools, announcements, etc.)
    shared/               Shared widgets, utilities, components
  web/                   Web-specific assets and configuration
  ios/                   iOS configuration
  android/               Android configuration
```

## Error Handling & Validation

- All services throw typed errors (`NotFoundError`, `ForbiddenError`, `ConflictError`, `ValidationError`, `UnauthorizedError`)
- Global error middleware maps each to the appropriate HTTP status code
- Controllers use `asyncHandler(...)` for automatic error handling
- All request bodies/params/queries are validated at the route level with Zod schemas
- Every response includes a `X-Request-Id` header for request correlation

## Authentication Flow

1. **Registration**: User creates account → verification email sent
2. **Email Verification**: User clicks verification link → account activated
3. **Login**: User provides credentials → JWT token returned
4. **Token Usage**: JWT token included in Authorization header for protected routes
5. **Password Reset**: User requests reset → email with reset link → set new password

## API Documentation

When the backend is running, interactive API documentation is available:
- **Swagger UI**: `http://localhost:5050/api/docs`
- **OpenAPI Spec**: `http://localhost:5050/api/docs.json`

## Development Workflow

- Active development happens on `develop` branch
- `main` branch receives final releases
- Branch naming: `feat/<area>-<short-desc>` or `fix/<area>-<short-desc>`
- Keep PRs focused and small for faster CI/CD

## License

TBD.
