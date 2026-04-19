#!/usr/bin/env bash
# HORIZON-aide-toolkit/scripts/archaeology.sh
# Run from inside any Horizon repo that has .claude/archaeology.config.json
#
# Usage:
#   bash ~/HORIZON-aide-toolkit/scripts/archaeology.sh
#   bash ~/HORIZON-aide-toolkit/scripts/archaeology.sh --refresh

set -e

REPO_DIR="$(pwd)"
CONFIG="$REPO_DIR/.claude/archaeology.config.json"
REFRESH=false

for arg in "$@"; do
  [[ "$arg" == "--refresh" ]] && REFRESH=true
done

# ── Verify config exists ──────────────────────────────────────────────────────
if [ ! -f "$CONFIG" ]; then
  echo ""
  echo "✗ .claude/archaeology.config.json not found in $(pwd)"
  echo ""
  echo "  Copy the template from the toolkit:"
  echo "  cp ~/HORIZON-aide-toolkit/templates/archaeology.config.json .claude/"
  echo "  Then edit it for this repo."
  exit 1
fi

# ── Read config fields ────────────────────────────────────────────────────────
REPO_TYPE=$(python3 -c "import json,sys; d=json.load(open('$CONFIG')); print(d['repoType'])")
REPO_NAME=$(python3 -c "import json,sys; d=json.load(open('$CONFIG')); print(d['repoName'])")
TOOLKIT_PATH=$(python3 -c "import json,sys; d=json.load(open('$CONFIG')); print(d['toolkitPath'])")
PERSONA=$(python3 -c "import json,sys; d=json.load(open('$CONFIG')); print(d['persona'])")
STACK_RULES=$(python3 -c "import json,sys; d=json.load(open('$CONFIG')); print(d['stackRules'])")
OUTPUT_PATH=$(python3 -c "import json,sys; d=json.load(open('$CONFIG')); print(d['outputPath'])")

TOOLKIT_PATH="${TOOLKIT_PATH/#\~/$HOME}"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   HORIZON AIDE Toolkit — Codebase Archaeology   ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Repo:     $REPO_NAME"
echo "  Type:     $REPO_TYPE"
echo "  Mode:     $([ "$REFRESH" = true ] && echo 'Refresh (preserving Decisions log)' || echo 'First run')"
echo ""

# ── Verify toolkit exists ─────────────────────────────────────────────────────
if [ ! -d "$TOOLKIT_PATH" ]; then
  echo "✗ Toolkit not found at: $TOOLKIT_PATH"
  echo "  Update toolkitPath in .claude/archaeology.config.json"
  exit 1
fi

# ── Verify persona exists ─────────────────────────────────────────────────────
PERSONA_PATH="$TOOLKIT_PATH/$PERSONA"
if [ ! -f "$PERSONA_PATH" ]; then
  echo "✗ Persona not found: $PERSONA_PATH"
  exit 1
fi

# ── Create specs/ and .claude/ directories ────────────────────────────────────
mkdir -p "$REPO_DIR/$OUTPUT_PATH"
mkdir -p "$REPO_DIR/.claude"

# ── Install skills from toolkit into repo ─────────────────────────────────────
echo "Installing skills..."
for skill in sdd-generate sdd-modify sdd-verify sdd-mock sdd-spec; do
  SKILL_DIR="$REPO_DIR/.claude/skills/$skill"
  mkdir -p "$SKILL_DIR"
  if [ -f "$TOOLKIT_PATH/skills/$skill/SKILL.md" ]; then
    cp "$TOOLKIT_PATH/skills/$skill/SKILL.md" "$SKILL_DIR/SKILL.md"
    echo "  ✓ $skill"
  fi
done

# ── Install rules ─────────────────────────────────────────────────────────────
mkdir -p "$REPO_DIR/.claude/rules"
if [ -f "$TOOLKIT_PATH/$STACK_RULES" ]; then
  cp "$TOOLKIT_PATH/$STACK_RULES" "$REPO_DIR/.claude/rules/stack.md"
  echo "  ✓ stack.md (from $STACK_RULES)"
fi
if [ -f "$TOOLKIT_PATH/rules/accessibility.md" ]; then
  cp "$TOOLKIT_PATH/rules/accessibility.md" "$REPO_DIR/.claude/rules/accessibility.md"
  echo "  ✓ accessibility.md"
fi

# ── Install spec-kit templates ────────────────────────────────────────────────
if [ -f "$TOOLKIT_PATH/spec-kit/spec-template.md" ]; then
  cp "$TOOLKIT_PATH/spec-kit/spec-template.md" "$REPO_DIR/$OUTPUT_PATH/spec-template.md"
  cp "$TOOLKIT_PATH/spec-kit/plan-template.md" "$REPO_DIR/$OUTPUT_PATH/plan-template.md"
  cp "$TOOLKIT_PATH/spec-kit/tasks-template.md" "$REPO_DIR/$OUTPUT_PATH/tasks-template.md"
  cp "$TOOLKIT_PATH/spec-kit/checklist-template.md" "$REPO_DIR/$OUTPUT_PATH/qa-checklist-template.md"
  echo "  ✓ spec-kit templates"
fi

# ── Compose CLAUDE.md ─────────────────────────────────────────────────────────
echo ""
echo "Composing CLAUDE.md..."

cat "$PERSONA_PATH" > "$REPO_DIR/CLAUDE.md"

if [ "$REPO_TYPE" = "backend-api" ]; then

  # ── Read find patterns from config ─────────────────────────────────────────
  ROUTES=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['findPatterns']['routes'])")
  MODELS=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['findPatterns']['models'])")
  DAOS=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['findPatterns']['daos'])")
  SERVICES=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['findPatterns']['services'])")
  SCHEMAS=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['findPatterns']['schemas'])")

  cat >> "$REPO_DIR/CLAUDE.md" << TASK

## Your task this session

You are performing a read-only codebase archaeology session on $REPO_NAME.
Create specs/architecture.md and specs/openapi.yaml only.
Do not modify any other application files.

STEP 0 — Check if specs/architecture.md already exists:
!\`ls specs/architecture.md 2>/dev/null && echo "EXISTS" || echo "NEW"\`

If EXISTS:
- Read specs/architecture.md first
- Preserve ## Decisions log section exactly as-is
- Print: "Refreshing existing architecture.md — Decisions log preserved"

If NEW:
- Print: "Generating architecture.md from scratch"

STEP 1 — Discover full source structure:
!\`find src -maxdepth 3 -type d | sort\`

Examine every folder. If a folder's purpose is unclear read one file
from it. Do not skip any folder.

STEP 2 — Read package.json:
!\`cat package.json\`

STEP 3 — Read server entry point:
!\`cat src/server.ts 2>/dev/null || cat src/app.ts 2>/dev/null\`

STEP 4 — Read all route files:
!\`find $ROUTES -name "index.ts" -not -name "*.test.ts" | sort\`
Read every file returned.

STEP 5 — Read all database model files:
!\`find $MODELS -name "*.ts" -not -path "*/node_modules/*" -not -name "*.test.ts" | sort\`
Read every file returned.

STEP 6 — Read all DAO files:
!\`find $DAOS -name "*.ts" -not -path "*/node_modules/*" -not -name "*.test.ts" | sort\`
Read every file returned.

STEP 7 — Read all service files:
!\`find $SERVICES -name "*.ts" -not -path "*/node_modules/*" -not -name "*.test.ts" | sort\`
Read every file returned.

STEP 8 — Read all schema files:
!\`find $SCHEMAS -name "*.ts" -not -path "*/node_modules/*" -not -name "*.test.ts" | sort\`
Read every file returned.

STEP 9 — Read any remaining folders not yet covered:
For each folder found in STEP 1 not yet read, run find and read its files.

Now produce specs/architecture.md with these sections:

## Last refreshed
[Today's date]

## Source tree
[Output of: find src -maxdepth 3 -type d | sort]

## Stack
All package versions from package.json. Capital One packages with purpose.

## Routes
| Method | Path | Handler | Auth required | Request schema | Response schema |
List v1 then v2 separately.

## Sequelize models
Each model: table name, all fields (JS name | DB column | type | nullable | notes),
associations, hooks.

## DAOs
Each DAO: file path, responsibility, methods (name + what it does + SQL file used),
which service consumes it.

## Service layer
Each service: file path, responsibility, methods, which DAOs it calls.

## Validation schemas
Each Zod schema: name, shape, which route uses it.

## SSO / Auth pattern
How auth is applied globally. Which routes are open. Permission levels.
What request.user contains.

## Error handling pattern
Global error handler location and shape. Domain error classes and HTTP codes.
Error response shape.

## Patterns observed
Naming conventions (Controllers, Services, DAOs, Models, Schemas, files).
Import conventions. Any patterns a developer must know before modifying code.

## Decisions log
(Append-only — never overwritten by archaeology runs)
[If EXISTS: reinsert preserved content here exactly]
[If NEW: leave empty]

Then produce specs/openapi.yaml derived from actual route handlers and schemas.
Reflect what code does, not assumptions.
One endpoint per route method. Include request schemas and response schemas
for 200/201, 400, 401, 404, 500 on every endpoint.

When done print exactly: API archaeology complete
TASK

elif [ "$REPO_TYPE" = "feature-monorepo" ]; then

  # ── Read workspaces from config ─────────────────────────────────────────────
  WORKSPACES=$(python3 -c "
import json
d = json.load(open('$CONFIG'))
for w in d['workspaces']:
    print(f\"{w['name']}|{w['path']}|{w['type']}\")
")

  # ── Cross-reference path ────────────────────────────────────────────────────
  CROSS_REF=$(python3 -c "
import json
d = json.load(open('$CONFIG'))
cr = d.get('crossReference')
print(cr['path'] if cr else 'NONE')
")

  cat >> "$REPO_DIR/CLAUDE.md" << TASK

## Your task this session

You are performing a read-only codebase archaeology session on $REPO_NAME.
This is a feature monorepo with multiple UI workspaces and a BFF API.
Create specs/architecture.md only. Do not create openapi.yaml —
that comes from the backend API repo.
Do not modify any other application files.

STEP 0 — Check if specs/architecture.md already exists:
!\`ls specs/architecture.md 2>/dev/null && echo "EXISTS" || echo "NEW"\`

If EXISTS:
- Read specs/architecture.md first
- Preserve ## Decisions log section exactly as-is
- Print: "Refreshing existing architecture.md — Decisions log preserved"

If NEW:
- Print: "Generating architecture.md from scratch"

STEP 1 — Discover full source structure across all workspaces:
!\`find . -maxdepth 4 -type d -not -path "*/node_modules/*" -not -path "*/.git/*" | sort\`

Examine every folder. If a folder's purpose is unclear read one file from it.

STEP 2 — Read root package.json and all workspace package.json files:
!\`cat package.json\`
$(echo "$WORKSPACES" | while IFS='|' read name path type; do
  echo "![\`cat $path/../package.json 2>/dev/null || echo 'NOT_FOUND'\`]"
done)

STEP 3 — For each UI workspace, read all component and hook files:
$(echo "$WORKSPACES" | while IFS='|' read name path type; do
  if [ "$type" = "ui" ] || [ "$type" = "shared" ]; then
    echo "Workspace: $name ($path)"
    echo "![\`find $path -name '*.tsx' -not -path '*/node_modules/*' -not -name '*.test.tsx' -not -name '*.stories.tsx' | sort\`]"
    echo "![\`find $path -name '*.ts' -not -path '*/node_modules/*' -not -name '*.test.ts' | sort\`]"
    echo "Read every file returned."
  fi
done)

STEP 3b — Specifically discover all hooks and modals:
$(echo "$WORKSPACES" | while IFS='|' read name path type; do
  if [ "$type" = "ui" ] || [ "$type" = "shared" ]; do
    echo "![\`find $path -name 'index.ts' -path '*/hooks/*' -not -path '*/node_modules/*' | sort\`]"
    echo "![\`find $path -name 'index.tsx' -path '*/modal*' -not -path '*/node_modules/*' | sort\`]"
    echo "Read every file returned — these are reusable hooks and modal shells."
  fi
done)

STEP 4 — Read BFF API files:
$(echo "$WORKSPACES" | while IFS='|' read name path type; do
  if [ "$type" = "api" ]; then
    echo "![\`find $path -name '*.ts' -not -path '*/node_modules/*' -not -name '*.test.ts' | sort\`]"
    echo "![\`find $path -name '*.js' -not -path '*/node_modules/*' -not -name '*.test.js' | sort\`]"
    echo "Read every file returned."
  fi
done)

STEP 5 — Cross-reference backend API contract if accessible:
![\`cat $CROSS_REF 2>/dev/null | head -100 || echo 'API_SPECS_NOT_ACCESSIBLE'\`]
If found, note which endpoints the UI calls vs what the API exposes.

Now produce specs/architecture.md with these sections:

## Last refreshed
[Today's date]

## Source tree
[Output of: find . -maxdepth 3 -type d -not -path "*/node_modules/*"]

## Stack
All package versions from root and workspace package.json files.
LightFrame config per workspace (packageType, domain, container, app).
All Capital One packages with purpose.

## LightFrame config
packageType per workspace. Registered routes. How each app mounts.

## Workspaces
For each workspace: name, path, purpose, what it renders.

## Component tree
| Component | Workspace | File path | Responsibility | Data source | Actions |
One row per component.

## Custom hooks
For every hook found under any hooks/ directory:
| Hook name | Workspace | File path | Purpose | What it wraps |
One row per hook. This section is critical — ticket writers and sdd-spec
use this to find existing hooks before writing new ones.

## Modals
For every modal component found:
| Modal name | Workspace | File path | Current state (empty shell / partial / complete) | Props accepted |
One row per modal. Note if the modal is a shell with placeholder content
vs a fully implemented modal.

## React Query usage
| Hook name | Workspace | Query key | Endpoint called | Method | Owner component |

## BFF routes
| Method | Path | Upstream API called | Auth |
All routes in api/src.

## API calls
| Hook/Component | Workspace | Method | BFF endpoint | Error handled |

## Omni components used
Every Omni component imported. Note custom overrides or non-standard usage.

## Patterns observed
Naming conventions. Error handling pattern. Loading state pattern.
How SSO token flows (BFF cookie pattern). Routing approach.
Any cross-workspace import issues observed.

## Gaps observed
Components without error handling. API calls without loading states.
BFF endpoints with no UI caller. Cross-workspace import violations.
Feature flag inconsistencies.

## Decisions log
(Append-only — never overwritten by archaeology runs)
[If EXISTS: reinsert preserved content here exactly]
[If NEW: leave empty]

When done print exactly: UI archaeology complete
TASK

fi

# ── Add .gitignore entry ──────────────────────────────────────────────────────
if [ -f "$REPO_DIR/.gitignore" ]; then
  if ! grep -q "CLAUDE.md" "$REPO_DIR/.gitignore"; then
    echo "CLAUDE.md" >> "$REPO_DIR/.gitignore"
    echo "  ✓ Added CLAUDE.md to .gitignore"
  fi
fi

echo ""
echo "────────────────────────────────────────────────────"
echo "Setup complete. CLAUDE.md composed for $REPO_TYPE."
echo ""
echo "Now run: claude"
echo ""
if [ "$REPO_TYPE" = "backend-api" ]; then
  echo "Paste this prompt:"
  echo "  Read package.json and the codebase following your instructions."
  echo ""
  echo "After Claude finishes:"
  echo "  → Review specs/architecture.md — check DAOs section is complete"
  echo "  → Review specs/openapi.yaml — check all routes are present"
  echo "  → Edit ## Decisions log to record any findings"
else
  echo "Paste this prompt:"
  echo "  Read all workspace files following your instructions."
  echo ""
  echo "After Claude finishes:"
  echo "  → Review specs/architecture.md — check all workspaces covered"
  echo "  → Review ## Gaps observed — these are real issues worth tracking"
  echo "  → Edit ## Decisions log to record any findings"
fi
echo ""
