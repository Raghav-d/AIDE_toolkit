# Stack Rules — Horizon Backend API

## Runtime
- Node.js 22+
- TypeScript 5.4+
- ESM project ("type": "module") — all imports use .js extension

## Framework
- Fastify 5.x
- Zod + fastify-type-provider-zod for schema validation
- Manual dependency injection — services constructed with new in server.ts
- No Inversify decorators despite package being listed

## Database
- Sequelize 6.x + PostgreSQL
- Raw pg pool for encryption DAO (via Piscina worker threads)
- freezeTableName: true on all models
- Column naming: abbreviated snake_case
  e.g. ownr_eid, cmptncy_cd, calbrtn_ratg_cd
- JS field naming: camelCase full words
- PKs: INTEGER autoIncrement unless UUID explicitly required
- Timestamps: cretd_ts (createdAt), last_updtd_ts (updatedAt)

## DAO layer
- Every service uses a DAO — never call Sequelize models directly from service
- DAOs live in src/dao/<domain>/index.ts
- Raw SQL queries live in src/database/sql/<domain>/
- HTTP client DAOs (OrganizationalHealth, Avatar, AdminJustification) use axios

## Auth
- SSO via @cof/pme-common-backend addAuthPreHandlersToRoutes
- Applied globally in app.ts/server.ts
- request.user = { userid: string, permissions: string[] }
- auth: false only for /health and export endpoints using API key
- CreateAndManagePermissions = groups:hrbp_user | groups:pmc_user

## Error handling
- try/catch in every route handler
- Error response shape: { error: true, message: string }
- Domain errors mapped to HTTP status codes
- Global error handler in app.ts

## Capital One packages
- @cof/horizon-logger — structured logging
- @cof/pme-common-backend — SSO, ERROR_MESSAGES, TaskResponse
- @cof/pme-crypto — field-level encryption (via Piscina workers)
- @cof/wine-cellar — initLogger

## Naming conventions
- Controllers: <Domain>Controller or <Domain>V2Controller
- Services: <Domain>Service / I<Domain>Service interface
- DAOs: <Domain>Dao
- Routes: src/routes/<domain>/index.ts
- Schemas: src/schema/<domain>/index.ts
- Models: src/database/models/<domain>/index.ts
- SQL: src/database/sql/<domain>/
- JSDoc @spec AC-N on every route handler
- JSDoc @api on every service method
