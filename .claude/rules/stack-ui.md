# Stack Rules — Horizon Feature Monorepo UI

## Runtime
- Node.js 22+
- TypeScript 5.4+
- Yarn 4.x (Berry), nodeLinker: node-modules
- Workspaces: ui/<name>/, ui/shared/, api/

## Frontend framework
- React 18.3.x
- Vite (via @cof/lightframe-vite-config-library defineLightframeUiConfig)
- React Router v6 within each MFE
- @cof/lightframe-client-lib for getPathPrefix() / getBoundSelectors()
- @cof/lightframe-global-store-ui-plugin for cross-MFE state

## Data layer
- TanStack React Query v5 (@tanstack/react-query ^5.x) — primary data layer
- React Context + useState for local UI state
- NO Redux slices — RTK is declared but unused at runtime
- react-hook-form + zod for form validation

## Design system
- @cof/omni-react ^5.x (primary)
- @cof/omni-tokens for design tokens
- @cof/omni-gravity-icons-react for icons
- styled-components or @emotion for custom styling

## Auth pattern
- UI never attaches auth headers
- BFF api/ reads C1_AT SSO cookie in onRequest hook
- Additional headers forwarded from shell: X-On-Behalf-Of, X-Permissions,
  X-Entitlements, X-Roles
- Use @cof/pme-common apiClient for BFF calls — auth handled server-side

## BFF (api/)
- Fastify 4.x with @cof/fastify-lightframe-plugin
- Routes proxy to backend API repos
- Auth applied at BFF level, never in UI

## Capital One packages
- @cof/pme-common — apiClient, NavBar, AssociateCard, useAutoSave,
  QueryWrapper, ApplicationAlertContext, navigateToPage
- @cof/client-side-logger — browser logging
- @cof/people-tech-stratum-browser-path — analytics/telemetry
- @cof/wine-cellar — server-side logging (BFF only)

## Testing
- Vitest + React Testing Library (UI)
- MSW 2.x for API mocking in tests
- Mocha + Chai (BFF)
- Cypress for E2E

## Naming conventions
- Components: PascalCase folders with index.tsx
- Hooks: use<Name> in hooks/ folder
- Types: types/ folder or co-located .types.ts
- No cross-workspace imports — shared code goes in ui/shared
- JSDoc @spec AC-N on every component handling an AC
- JSDoc @api on every React Query hook

## Patterns
- Loading state: <Spinner /> from Omni or inline loading text
- Error state: ApplicationAlertContext or inline error component
- Never show undefined/null data — always guard with loading check
- Accessibility: aria-label on interactive elements, role="alert" on errors
