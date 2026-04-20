---
name: sdd-modify
description: >
  Patch an existing file in the repo using updated specs.
  Also handles new file creation when a path is specified that does not
  yet exist. Invoke when the user says "modify", "patch", "update existing",
  "change an existing component", "create hook", or runs /sdd-modify.
  Never rewrites the whole file — applies surgical, non-breaking changes.
allowed-tools: Read, Write, Bash(find . -name *), Bash(cat *), Bash(ls *), Bash(mkdir *), Bash(npx tsc *), Bash(npx vitest *)
argument-hint: "<relative/path/to/File.tsx>"
---

# SDD Modify Skill

You are executing the Spec-Driven Development **modify** workflow.
Apply the minimum change that satisfies the updated spec. Break nothing.

## Step 0 — Check argument

If $ARGUMENTS is empty, list existing components and stop:

```
!`find . -name "*.tsx" -not -path "*/node_modules/*" -not -name "*.test.tsx" -not -name "*.stories.tsx" | head -20`
```

Print: "No file specified. Re-run with a path, e.g:
`/sdd-modify src/features/TaskList/TaskList.tsx`"

## Step 1 — Check if file exists (NEW vs EXISTING)

```
!`ls $ARGUMENTS 2>/dev/null && echo "EXISTS" || echo "NEW"`
```

If NEW:
- This is a new file — treat as creation, not modification
- Read specs/prd.md to understand what this file should contain
- Read architecture.md ## Custom hooks section to check for similar
  existing hooks before writing anything new
- Print: "File does not exist — creating new file at $ARGUMENTS"
- Skip Steps 2-3, go directly to Step 4 (creation mode)
- In creation mode: write the complete file from scratch based on prd.md
- Generate a companion test file alongside it

If EXISTS:
- Continue to Step 2 (normal modify flow)

## Step 2 — Load target file and related files (EXISTING only)

Use the Read tool to read the target file.
Do not use cat — Read tool only.

Find and read related files:
```
!`find . -name "*.test.tsx" -not -path "*/node_modules/*" | grep -i "$(basename $(dirname $ARGUMENTS))" | head -5`
```

```
!`find . -name "*.test.ts" -not -path "*/node_modules/*" | grep -i "$(basename $(dirname $ARGUMENTS))" | head -5`
```

Read the test files found that relate to the target.

## Step 3 — Load updated specs

Use the Read tool to read specs/prd.md.

Read specs/openapi.yaml only if it exists:
```
!`cat specs/openapi.yaml 2>/dev/null || echo "NO_OPENAPI — UI repo, skipping"`
```

Read specs/architecture.md to understand:
- ## Custom hooks — existing hooks to reuse, never reimplement
- ## Types and constants — TypeScript interfaces and enum values
- ## Patterns observed — conventions this codebase follows

## Step 4 — Multi-file ordering rule

When prd.md ## Affected files lists multiple files, process in this order:
1. New hooks first (no dependencies on other new files)
2. New service/mutation hooks (depend on types only)
3. Modal or component being implemented (depends on hooks)
4. Trigger component (depends on modal props)
5. Parent component (depends on trigger props)
6. BFF route file (independent, can be last)

Only process the single file in $ARGUMENTS in this run.
The developer will run /sdd-modify again for each subsequent file.
Do not attempt to modify multiple files in one run.

## Step 5 — Change impact analysis (EXISTING files only)

Identify:
1. Affected sections — functions, JSX blocks, types the new spec touches
2. Preserved sections — everything not mentioned in spec (do not touch)
3. New AC delta — ACs not yet handled in this file
4. Existing hooks from architecture.md ## Custom hooks that must be used
5. Risk surface — anything that could break existing tests

Print analysis (max 15 lines).
Ask: "Proceed with patch? (yes / adjust)"
Wait for confirmation.

## Step 6 — Apply the change

Rules — apply to both creation and modification:
- Never rewrite code the spec does not mention (modify mode)
- Preserve all existing @spec / @figma / @api JSDoc tags
- Add new @spec tags for every new AC implemented
- Use hooks from architecture.md ## Custom hooks — never reimplement
- Use Omni/Gravity components from architecture.md ## Omni components used
- Add tests for new ACs without removing existing test cases
- No `any` types in TypeScript
- Follow naming conventions from architecture.md ## Patterns observed

After writing, check types if TypeScript project:
```
!`npx tsc --noEmit 2>&1 | head -20`
```

Fix type errors before reporting completion.

## Step 7 — Regression check (EXISTING files only)

```
!`npx vitest run 2>&1 | tail -20`
```

Fix failures caused by your change.
Report pre-existing failures — do not fix them silently.

## Step 8 — Diff summary

Print a plain summary of what was created or changed:

```
Created/Modified: [file path]
  + [what was added, referencing AC numbers]
  + [hooks used from architecture.md]
  + [test cases added]

Next file to run:
  /sdd-modify [next file from prd.md ## Affected files ordering]
```

Always print the next file to run so the developer knows what comes next.
