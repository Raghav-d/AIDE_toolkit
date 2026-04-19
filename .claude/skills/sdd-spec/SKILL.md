---
name: sdd-spec
description: >
  Strengthen a raw Jira ticket into a production-ready spec using
  architecture.md knowledge. Reads specs/jira-ticket.json and
  specs/architecture.md, fills in specs/spec-template.md, and
  produces specs/prd.md ready for human verification.
  Invoke when the user says "strengthen spec", "prepare PRD",
  "spec the ticket", or runs /sdd-spec.
allowed-tools: Read, Write, Bash(cat *), Bash(ls *), Bash(find . -name *)
argument-hint: "[specs/jira-ticket.json]"
---

# SDD Spec Skill

Strengthen a raw Jira ticket into a spec using codebase knowledge.

## Step 0 — Load inputs

```
!`cat specs/jira-ticket.json`
```

```
!`cat specs/architecture.md`
```

```
!`cat specs/spec-template.md`
```

```
!`cat .claude/rules/stack.md`
```

If jira-ticket.json is missing, stop and print:
"specs/jira-ticket.json not found. Run /jira TICKET-KEY first."

If architecture.md is missing, stop and print:
"specs/architecture.md not found. Run archaeology.sh first."

## Step 0b — For UI tickets: read existing code before strengthening

Parse the jira-ticket.json description to find:
- Any file paths mentioned (target component, related components)
- Any hook names mentioned (existing hooks to use)
- Any component names mentioned

If this appears to be a UI ticket (label = UI, or description mentions
modal/component/button/hook):

Read the target component if specified:
Use the Read tool to read the file at the path mentioned in the ticket.
If no path is mentioned, search architecture.md ## Modals section
to find likely candidates based on component names in the description.

Read related components if specified:
Use the Read tool to read each file mentioned under "Related components".

Search for existing hooks:
Check architecture.md ## Custom hooks section for hooks relevant to
the ticket's domain (e.g. if ticket mentions "show once" or "persist",
look for hooks that handle localStorage or disabled state).

This step prevents duplicating logic that already exists in the codebase.
Document what you found:
"Found existing: [component/hook name] at [path] — will use this, not reimplement."

## Step 1 — Parse Jira ticket

Jira wiki markup conventions used by Capital One:
- `*` bullet points = potential acceptance criteria
- `[label|URL]` = linked resource (Figma, Confluence etc)
- `Tech Note -` prefix = developer note, NOT an AC
- `~TICKET-KEY` = reference to another ticket
- `*existing*` / `*NEW*` = emphasis markers, strip them

Extract:
- Summary (ticket title)
- All `*` bullet points as candidate ACs
- Tech notes (separate section, not ACs)
- Figma links (already in figma_links field)
- References to other tickets
- Any explicit API endpoint mentions

## Step 2 — Classify the work

Determine from the ticket and architecture.md:

**Repo type** (from architecture.md repoType or stack):
- `backend-api` → generates route + service + DAO + model files
- `feature-monorepo` → generates/modifies UI components + BFF routes

**Work type**:
- New endpoint + new tables → `sdd-generate` (new files)
- New endpoint + existing tables → `sdd-generate` (partial new)
- Change to existing endpoint → `sdd-modify`
- UI component change only → `sdd-modify`
- Full-stack (UI + BFF + API) → flag as multi-repo work

**For feature-monorepo:** identify affected workspace:
- Read workspaces from architecture.md ## Workspaces section
- Match ticket keywords to workspace names
- If ambiguous, list candidates and mark as NEEDS HUMAN INPUT

Print classification clearly:
```
Classification: [backend-api | feature-monorepo]
Work type:      [sdd-generate | sdd-modify | multi-repo]
Affected:       [workspace name or file path]
Skill to run:   [/sdd-generate ComponentName | /sdd-modify path/to/file]
```

## Step 3 — Strengthen acceptance criteria

For each candidate AC from Step 1:

**If backend-api:**
- Add HTTP method and path (follow versioning pattern from architecture.md)
- Add auth requirement (check SSO pattern from architecture.md)
- Add request body shape (follow Zod schema conventions)
- Add response shape (follow existing response patterns)
- Add error cases: 400 (validation), 401 (unauth), 404 (not found), 500
- Add DB transaction requirement if multiple tables written atomically

**If feature-monorepo:**
- Add which workspace is affected
- Add which BFF endpoint is called
- Add loading state requirement
- Add error state requirement
- Add accessibility requirement (aria labels, focus management)
- Note: no auth headers in UI — BFF handles auth via C1_AT cookie

## Step 4 — Translate field names (backend-api only)

For any new DB fields mentioned in the ticket:
- Apply abbreviated snake_case column naming from architecture.md patterns
- Match freezeTableName: true convention
- Match PK pattern (INTEGER autoIncrement unless UUID explicitly stated)
- Follow timestamp pattern: cretd_ts, last_updtd_ts

## Step 5 — Identify affected files

Cross-reference ACs against architecture.md:

**For backend-api:**
- Route: src/routes/<domain>/index.ts
- Schema: src/schema/<domain>/index.ts
- Service: src/services/<domain>/index.ts
- DAO: src/dao/<domain>/index.ts (always needed for new service)
- Model: src/database/models/<domain>/index.ts (only if new table)
- server.ts: always modified to wire new controller

**For feature-monorepo:**
- UI component files in affected workspace
- BFF route file in api/src/routes/
- Shared hooks in ui/shared if reusable

## Step 6 — Flag ambiguities

List anything that cannot be determined from the ticket or architecture.md:

```
NEEDS HUMAN INPUT:
- [specific question]
- [specific question]
```

Do not guess. Surface these explicitly.

## Step 7 — Write specs/prd.md

Fill in specs/spec-template.md with all strengthened content.
Add these Horizon-specific sections after the standard template:

```markdown
## Classification
- Work type: [sdd-generate | sdd-modify]
- Repo type: [backend-api | feature-monorepo]
- Affected workspace: [name] (feature-monorepo only)
- Skill to run: [/sdd-generate X | /sdd-modify path]

## Affected files
### New files
- [list]
### Modified files
- [list]

## Tech notes (from ticket — not ACs)
[Copy tech notes from ticket here for reference]

## Cross-repo dependencies
[Any UI or API changes needed in sibling repos]
```

Then print exactly:
"Spec ready — review specs/prd.md and answer any NEEDS HUMAN INPUT
items before running code generation."
