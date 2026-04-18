---
name: jira
description: >
  Fetch a Jira ticket from a self-hosted Jira Server/Data Center instance
  using a Bearer PAT and save it to specs/jira-ticket.json.
  Invoke when the user says "fetch ticket", "get story", "read jira",
  "pull ticket", or provides a Jira issue key like PROJ-123 or ABC-456.
  Also automatically extracts any Figma URLs found in the ticket description
  or comments for use by the figma skill.
allowed-tools: Read, Write, Bash(python3 *), Bash(cat *), Bash(ls *), Bash(mkdir *)
argument-hint: "<ISSUE-KEY>"
---

# Jira Skill — Fetch Ticket

You are executing the jira fetch workflow.
Your goal: retrieve a Jira ticket and save it to specs/jira-ticket.json.

## Step 0 — Check argument

If $ARGUMENTS is empty, stop and print:
"No issue key provided. Re-run with a key, e.g: /jira HRTP-8050"

Extract the issue key — it is the first token in $ARGUMENTS.

## Step 1 — Check environment

Verify .env exists and contains JIRA_PAT:

```
!`ls .env 2>/dev/null || echo "NO_ENV"`
```

```
!`cat .env`
```

If .env is missing or JIRA_PAT is empty, stop and print:
"`.env` not found or JIRA_PAT is not set.
Copy `.env.example` → `.env` and fill in your PAT.
Get a PAT: Jira → Profile → Personal Access Tokens → Create token"

## Step 2 — Create specs directory

!`mkdir -p specs`

## Step 3 — Fetch the ticket

Use the Bash tool to run the Python script with the actual issue key
from $ARGUMENTS. Do not use a backtick bash block for this step.
Call it as a Bash tool directly:

python3 .claude/skills/jira/get_ticket.py {ISSUE_KEY} --out specs/jira-ticket.json

Replace {ISSUE_KEY} with the actual value extracted from $ARGUMENTS.
If the script fails, print the error and stop.

## Step 4 — Read and summarise output

After the script succeeds, read the output file using the Read tool
(not a bash cat command). Parse the JSON and print:

Jira ticket fetched — specs/jira-ticket.json
─────────────────────────────────────────────
Key:      [key]
Summary:  [summary]
Status:   [status]
Assignee: [assignee]
Figma links: [count or "none"]

If figma_links is non-empty, print:
"Run /figma --from-jira specs/jira-ticket.json to export design specs."

If figma_links is empty, print:
"No Figma links found in this ticket."

## Step 5 — Next step guidance

If figma_links were found:
"Ready for Figma export. Run:
  `/figma --from-jira specs/jira-ticket.json`"
