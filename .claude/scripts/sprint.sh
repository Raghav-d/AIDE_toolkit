#!/usr/bin/env bash
# HORIZON-aide-toolkit/scripts/sprint.sh
# Per-ticket workflow. Run from inside any Horizon repo.
#
# Usage:
#   bash ~/HORIZON-aide-toolkit/scripts/sprint.sh <JIRA-KEY>
#   bash ~/HORIZON-aide-toolkit/scripts/sprint.sh HRTP-8050

set -e

REPO_DIR="$(pwd)"
CONFIG="$REPO_DIR/.claude/archaeology.config.json"
JIRA_KEY="$1"

if [ -z "$JIRA_KEY" ]; then
  echo ""
  echo "Usage: bash sprint.sh <JIRA-KEY>"
  echo "  e.g. bash sprint.sh HRTP-8050"
  exit 1
fi

if [ ! -f "$CONFIG" ]; then
  echo "✗ .claude/archaeology.config.json not found"
  echo "  Run archaeology.sh first to set up this repo"
  exit 1
fi

REPO_TYPE=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['repoType'])")
REPO_NAME=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['repoName'])")
TOOLKIT_PATH=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['toolkitPath'])")
PERSONA=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d['persona'])")
TOOLKIT_PATH="${TOOLKIT_PATH/#\~/$HOME}"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   HORIZON AIDE Toolkit — Sprint Workflow        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Repo:   $REPO_NAME"
echo "  Ticket: $JIRA_KEY"
echo ""

# ── Verify prerequisites ──────────────────────────────────────────────────────
if [ ! -f "specs/architecture.md" ]; then
  echo "✗ specs/architecture.md not found"
  echo "  Run archaeology.sh first before sprint workflow"
  exit 1
fi

# ── GATE 1: Fetch Jira ticket ─────────────────────────────────────────────────
echo "GATE 1 — Fetching Jira ticket..."
echo ""

PERSONA_PATH="$TOOLKIT_PATH/$PERSONA"
cat "$PERSONA_PATH" > "$REPO_DIR/CLAUDE.md"

cat >> "$REPO_DIR/CLAUDE.md" << TASK

## Your task this session

Fetch the Jira ticket and strengthen it into a spec.

STEP 1 — Fetch ticket:
Use the jira skill: /jira $JIRA_KEY

STEP 2 — Strengthen spec:
Use the sdd-spec skill: /sdd-spec

STEP 3 — If Figma links found in ticket:
Use the figma skill: /figma --from-jira specs/jira-ticket.json

When done print exactly: Spec ready — awaiting human review
TASK

echo "CLAUDE.md composed for Gate 1."
echo ""
echo "── HUMAN GATE 1 ──────────────────────────────────────"
echo "Run: claude"
echo ""
echo "Inside Claude Code:"
echo "  /jira $JIRA_KEY"
echo "  /sdd-spec"
echo "  /figma --from-jira specs/jira-ticket.json  (if Figma links found)"
echo ""
echo "Then review:"
echo "  → specs/jira-ticket.json  — raw ticket data"
echo "  → specs/prd.md            — strengthened spec"
echo "  → specs/figma-export.json — design tokens (if applicable)"
echo ""
echo "Answer any NEEDS HUMAN INPUT items in specs/prd.md"
echo "Edit specs/prd.md freely — this is your checkpoint"
echo ""
read -p "Press Enter when specs/prd.md is approved to continue..." _

# ── GATE 2: Generate code ─────────────────────────────────────────────────────
echo ""
echo "GATE 2 — Code generation..."
echo ""

cat "$PERSONA_PATH" > "$REPO_DIR/CLAUDE.md"

cat >> "$REPO_DIR/CLAUDE.md" << TASK

## Your task this session

Generate or modify code based on the approved spec.

Read these files first:
- specs/prd.md
- specs/architecture.md
- specs/openapi.yaml (if present)

Determine from specs/prd.md whether this is:
- New files → use /sdd-generate
- Existing files → use /sdd-modify

Follow all patterns from specs/architecture.md exactly.
When done print exactly: Code ready — awaiting human review
TASK

echo "CLAUDE.md composed for Gate 2."
echo ""
echo "── HUMAN GATE 2 ──────────────────────────────────────"
echo "Run: claude"
echo ""
echo "Inside Claude Code:"
echo "  Read specs/prd.md and specs/architecture.md"
echo "  then generate or modify following your instructions"
echo ""
echo "Then verify:"
echo "  → All files listed in specs/prd.md were created/modified"
echo "  → auth: true present on new routes (API repos)"
echo "  → DB transaction present where AC requires atomicity"
echo "  → No any types in generated TypeScript"
echo ""
read -p "Press Enter when generated code is approved to continue..." _

# ── GATE 3: Tests ─────────────────────────────────────────────────────────────
echo ""
echo "GATE 3 — Test verification..."
echo ""

if [ "$REPO_TYPE" = "backend-api" ]; then
  echo "── HUMAN GATE 3 ──────────────────────────────────────"
  echo "Run tests:"
  echo "  npm test -- --testPathPattern=<feature>"
  echo ""
  echo "Verify:"
  echo "  → All AC test cases pass"
  echo "  → No existing tests broken"
  echo ""
else
  echo "── HUMAN GATE 3 ──────────────────────────────────────"
  echo "Run tests:"
  echo "  cd ui/<workspace> && npm test"
  echo ""
  echo "Verify:"
  echo "  → All AC test cases pass"
  echo "  → No existing tests broken"
  echo ""
fi

read -p "Press Enter when tests pass to continue..." _

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────"
echo "Sprint workflow complete for $JIRA_KEY"
echo ""
echo "Next steps:"
echo "  → Raise PR"
echo "  → Update specs/architecture.md ## Decisions log"
echo "    with any architectural decisions made during this ticket"
echo "  → At sprint end: refresh architecture.md:"
echo "    bash ~/HORIZON-aide-toolkit/scripts/archaeology.sh --refresh"
echo ""
