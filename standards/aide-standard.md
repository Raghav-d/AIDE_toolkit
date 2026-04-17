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
- Verification checklist:
  - [ ] `auth: true` on all new routes (API repos)
  - [ ] DB transaction present where multiple tables written
  - [ ] No `any` types in TypeScript
  - [ ] All ACs from prd.md have corresponding code
  - [ ] No cross-workspace imports (UI monorepos)

### Gate 3 — Tests
- Run tests against generated code
- **Human reviews test results**
- All AC test cases must pass
- No existing tests broken

---

## Jira ticket standards

For AIDE to produce accurate specs, tickets must follow these conventions.

### Required fields
- **Summary**: concise feature description
- **Description**: user story + acceptance criteria
- **Label**: `UI` | `API` | `DB` | `infra`
- **Linked issues**: UI ticket must link to its API ticket and vice versa

### Acceptance criteria format
Write ACs as `*` bullet points in the description:

```
* When the user clicks X, Y happens
* The endpoint accepts ownerEid, associateEid, cycleId
* On success, return 201 with the created record
* On duplicate (same associateEid + ownerEid + cycleId), return 400
```

### Tech notes
Prefix developer notes with `Tech Note -` so AIDE separates them from ACs:

```
Tech Note - This endpoint will be called by the GenAI service, not the UI
Tech Note - Use existing CalibrationService pattern for error handling
```

### Figma links
Paste Figma design URLs directly in the description. AIDE extracts them
automatically. Use design links not prototype links where possible.

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
