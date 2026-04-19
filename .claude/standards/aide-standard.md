# HORIZON AIDE Standard
# AI-Driven Engineering — Conventions and Workflow

Version: 0.1 (proof of concept)
Owner: PME Engineering

---

## What AIDE is

AIDE is a set of conventions and Claude Code skills that turn a Jira ticket
into production-quality code — with mandatory human verification at every gate.
It does not replace developers. It removes boilerplate, enforces patterns, and
surfaces spec gaps before a line of code is written.

---

## Repo onboarding (one-time per repo)

1. Clone the toolkit:
   ```bash
   git clone <internal-url>/HORIZON-aide-toolkit ~/HORIZON-aide-toolkit
   ```

2. Copy the right config into your repo:
   ```bash
   # For backend API repos:
   cp ~/HORIZON-aide-toolkit/templates/config-calibration-api.json \
      .claude/archaeology.config.json

   # For feature monorepos:
   cp ~/HORIZON-aide-toolkit/templates/config-path-myteam.json \
      .claude/archaeology.config.json
   ```

3. Edit `.claude/archaeology.config.json` — update repoName and workspaces.

4. Run archaeology:
   ```bash
   bash ~/HORIZON-aide-toolkit/scripts/archaeology.sh
   ```

5. Review and commit `specs/architecture.md`.
   Add `CLAUDE.md` to `.gitignore` (script does this automatically).

---

## Sprint workflow (per ticket)

```bash
bash ~/HORIZON-aide-toolkit/scripts/sprint.sh HRTP-8050
```

The script walks you through three gates:

### Gate 1 — Spec
- Fetches Jira ticket → `specs/jira-ticket.json`
- Strengthens ticket into PRD → `specs/prd.md`
- Extracts Figma links → `specs/figma-export.json`
- **Human reviews and approves `specs/prd.md`**
- Answer all NEEDS HUMAN INPUT items before proceeding

### Gate 2 — Code
- Runs `sdd-generate` or `sdd-modify` against affected files
- **Human reviews generated code**
- Verification checklist — API repos:
    - [ ] `auth: true` on all new routes
    - [ ] DB transaction present where multiple tables written
    - [ ] No `any` types in TypeScript
    - [ ] All ACs from prd.md have corresponding code
    - [ ] DAO file generated alongside new service
- Verification checklist — UI repos:
    - [ ] No `any` types in TypeScript
    - [ ] All ACs from prd.md have corresponding code
    - [ ] No cross-workspace imports
    - [ ] Existing hooks used — nothing reimplemented that already exists
    - [ ] Omni/Gravity components used (not custom HTML equivalents)
    - [ ] Loading state present on all async operations
    - [ ] Error state present on all async operations
    - [ ] `aria-label` on all interactive elements
    - [ ] MSW mock handlers generated if API endpoint is TBD

### Gate 3 — Tests
- Run tests against generated code
- **Human reviews test results**
- All AC test cases must pass
- No existing tests broken

---

## Jira ticket standards

For AIDE to produce accurate specs, tickets must follow these conventions.
Incomplete tickets produce incomplete or incorrect code. The ticket writer
is responsible for providing enough detail that a developer who has never
seen the codebase can understand what to build.

### Required fields (all tickets)

- **Summary**: concise feature description (one line)
- **Description**: user story + acceptance criteria (see format below)
- **Label**: `UI` | `API` | `DB` | `infra`
- **Linked issues**: UI ticket must link to its API ticket and vice versa

### Acceptance criteria format

Write ACs as `*` bullet points. Each AC must be specific and testable.
One behaviour per AC. Never vague ("the modal should work correctly").

```
* When the user clicks X, Y happens
* The endpoint accepts ownerEid, associateEid, cycleId as required fields
* On success, return 201 with the created session record
* On duplicate submission (same key combination), return 409
* The button remains disabled until the checkbox is checked
```

### Tech notes

Prefix developer notes with `Tech Note -` so AIDE separates them from ACs:

```
Tech Note - This endpoint will be called by the GenAI service, not the UI
Tech Note - Use existing CalibrationService pattern for error handling
Tech Note - calling Gen AI API endpoints — not required for this story
```

### Figma links

Paste Figma design links directly in the description. AIDE extracts them
automatically. Always use design links (not prototype links). Always include
the specific node-id so AIDE fetches the exact frame, not the whole file:

```
https://www.figma.com/design/FILE_KEY/Title?node-id=55836-9551
```

---

## Additional requirements for UI tickets

UI tickets require more context than API tickets because the codebase has
existing components and hooks that must be reused — not duplicated.
A new developer running AIDE must be able to find all relevant files
from the ticket alone, without reading the whole codebase.

### Target component (required)

The exact file path of the component to modify or create:

```
Target component: ui/associate/src/modals/pathAiAssistantModal/index.tsx
```

If creating a new component, specify the intended path and name.

### Related components (required if applicable)

Other files that need updating alongside the target — parent components
that own state, sibling components that receive new props:

```
Related components:
- ui/associate/src/components/common/pathAiAssistantButton/index.tsx
  (CTA that triggers modal — needs new props passed down)
- ui/associate/src/components/calibrationTemplate/strengthDevelopment/index.tsx
  (parent that owns modal open state — needs prop additions)
```

### Existing hooks to use (required if applicable)

Hooks that already solve part of the problem. AIDE must use these —
never reimplement logic that already exists:

```
Existing hooks:
- usePersistedDisabledModalButton — handles localStorage show-once logic
```

If you are not sure what hooks exist, ask the tech lead before writing the ticket.

### API contract (required)

Specify endpoint, method, request body, response shape, and error codes.
If the endpoint is not ready, say so explicitly and name the owner:

```
API contract:
POST /pme/my-team/api/acknowledge
Request: { cycle_id, ppl_eid, associate_eid, competency_code, competency_kind }
Response: { llm_session_id: string }
Errors: 201 Created | 409 Conflict (already acknowledged) | 500
Note: endpoint TBD — use MSW mock. Owner: Kishan Ramoliya
```

### Show-once / persistence behaviour (required if applicable)

If a UI element should only show once, specify the persistence strategy:

```
Show-once behaviour:
localStorage key: path_ai_ack_{cycle_id}_{ppl_eid}_{associate_eid}_{competency_code}_{competency_kind}
Resets: never
Existing hook handles this: usePersistedDisabledModalButton
```

### Dismiss / cancel behaviour (required if applicable)

What happens when the user dismisses without completing the action:

```
Cancel behaviour: closes modal only, no API call, modal shows again on next click
```

Or if an API call is needed:

```
Cancel behaviour: PUT /endpoint to set status to cancelled, then close modal
```

---

## Architecture maintenance

`specs/architecture.md` is a living document. Keep it accurate.

### After every sprint
Append to `## Decisions log`:
```markdown
### HRTP-8050 — 2026-04-17
Added AcknowledgmentController + ChatSession + Acknowledgment tables.
Chose UUID PK for ChatSession (not INTEGER) because sessions need globally
unique IDs for GenAI service correlation.
```

### After every sprint end
Refresh the generated sections:
```bash
bash ~/HORIZON-aide-toolkit/scripts/archaeology.sh --refresh
```

The `## Decisions log` is preserved. All other sections are regenerated.

---

## Skill reference

| Skill | Command | When to use |
|---|---|---|
| jira | `/jira HRTP-8050` | Fetch ticket from Jira |
| figma | `/figma --from-jira specs/jira-ticket.json` | Export Figma design |
| sdd-spec | `/sdd-spec` | Strengthen ticket into PRD |
| sdd-generate | `/sdd-generate ComponentName` | New files from spec |
| sdd-modify | `/sdd-modify path/to/File.tsx` | Modify existing file |
| sdd-verify | `/sdd-verify path/to/File.tsx` | Audit file vs PRD |
| sdd-mock | `/sdd-mock specs/openapi.yaml` | Generate MSW handlers |

---

## Future: HumanLayer integration

The three gate points above (spec, code, tests) are designed to be automated
with HumanLayer when the team is ready. Each `read -p` prompt in `sprint.sh`
will be replaced with a HumanLayer approval request — enabling async review
via Slack without blocking the terminal.

Gate definitions are already specified above. Implementation is a sprint of
work replacing the bash prompts with HumanLayer API calls.

---

## Repo config reference

### `repoType` values
- `backend-api` — pure API repo (src/ structure, produces openapi.yaml)
- `feature-monorepo` — UI + BFF in one repo (ui/ workspaces + api/)

### Workspace `type` values
- `ui` — React app workspace
- `shared` — shared hooks/services, no entry point
- `api` — BFF Fastify server

---

## Questions and contributions

File issues in the HORIZON-aide-toolkit repo.
To add support for a new repo type, add a config template and update
`archaeology.sh` with the new `repoType` branch.
