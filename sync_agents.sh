#!/usr/bin/env bash
# sync_agents.sh — Generate tool-specific agent & skill configs from canonical sources
#
# Canonical sources:
#   agents/*.md                — Agent definitions (body = system prompt)
#   skills/*/SKILL.md          — Skill definitions (copied as-is)
#
# Targets:
#   .claude/agents/*.md        — Claude Code subagents (YAML frontmatter + body)
#   .claude/skills/*/SKILL.md  — Claude Code skill refs (copy of SKILL.md only)
#   .opencode/agents/*.md      — OpenCode agents (YAML frontmatter + body)
#   .opencode/skills/*/SKILL.md — OpenCode skill refs (copy of SKILL.md only)
#
# Usage: bash scripts/sync_agents.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$REPO_ROOT/agents"
SKILLS_DIR="$REPO_ROOT/skills"
CLAUDE_DIR="$REPO_ROOT/.claude/agents"
CLAUDE_SKILLS_DIR="$REPO_ROOT/.claude/skills"
OPENCODE_DIR="$REPO_ROOT/.opencode/agents"
OPENCODE_SKILLS_DIR="$REPO_ROOT/.opencode/skills"

# ─── Helpers ───────────────────────────────────────────────────────────────────

# Extract body (everything after the closing ---) from a markdown file with YAML frontmatter
extract_body() {
  local file="$1"
  # Skip lines until we pass the second '---', then print the rest
  awk 'BEGIN{n=0} /^---$/{n++; if(n==2){found=1; next}} found{print}' "$file"
}

# Extract a frontmatter value by key (simple single-line values only)
fm_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    BEGIN{in_fm=0}
    /^---$/{in_fm++; next}
    in_fm==1 && $0 ~ "^"key":" {
      sub("^"key":[ ]*", ""); gsub(/^["'\'']|["'\'']$/, ""); print; exit
    }
  ' "$file"
}

# ─── Tool-specific frontmatter definitions ─────────────────────────────────────
#
# Each function writes the full YAML frontmatter for a given agent + tool combo.
# This is the single place to update when tool specs change.

claude_frontmatter__ddd_expert() {
  cat <<'YAML'
---
name: DDD Expert
description: >-
  A domain expert and DDD specialist that discovers domain models, analyzes
  architecture candidates, and enforces ubiquitous language governance across
  all project artifacts.
model: opus
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebSearch
  - Task
skills:
  - .claude/skills/ddd_discover/SKILL.md
  - .claude/skills/ddd_architecture/SKILL.md
  - .claude/skills/ddd_enforce/SKILL.md
---
YAML
}

opencode_frontmatter__ddd_expert() {
  cat <<'YAML'
---
description: >-
  A domain expert and DDD specialist that discovers domain models, analyzes
  architecture candidates, and enforces ubiquitous language governance across
  all project artifacts.
mode: primary
temperature: 0.2
tools:
  Bash: true
  Read: true
  Write: true
  Edit: true
  Glob: true
  Grep: true
  WebSearch: true
  Task: true
permission:
  edit: allow
  bash: allow
---
YAML
}

# ─── Agent registry ────────────────────────────────────────────────────────────
# Map filename stems to their frontmatter functions.
# To add a new agent: (1) add agents/foo.md, (2) add frontmatter functions above,
# (3) add an entry here.

AGENTS=("ddd-expert")

# ─── Generate ──────────────────────────────────────────────────────────────────

mkdir -p "$CLAUDE_DIR" "$OPENCODE_DIR"

for agent in "${AGENTS[@]}"; do
  src="$SOURCE_DIR/$agent.md"
  if [[ ! -f "$src" ]]; then
    echo "WARN: $src not found, skipping" >&2
    continue
  fi

  # Normalize agent name to function suffix: novel-scout → novel_scout
  func_suffix="${agent//-/_}"

  body="$(extract_body "$src")"

  # ── Claude Code ──
  claude_func="claude_frontmatter__${func_suffix}"
  if declare -f "$claude_func" > /dev/null 2>&1; then
    {
      $claude_func
      echo "$body"
    } > "$CLAUDE_DIR/$agent.md"
    echo "OK  .claude/agents/$agent.md"
  else
    echo "WARN: no Claude frontmatter for $agent" >&2
  fi

  # ── OpenCode ──
  opencode_func="opencode_frontmatter__${func_suffix}"
  if declare -f "$opencode_func" > /dev/null 2>&1; then
    {
      $opencode_func
      echo "$body"
    } > "$OPENCODE_DIR/$agent.md"
    echo "OK  .opencode/agents/$agent.md"
  else
    echo "WARN: no OpenCode frontmatter for $agent" >&2
  fi
done

# ─── Skills Sync ───────────────────────────────────────────────────────────────
# Copy SKILL.md files from skills/*/ into .claude/skills/ and .opencode/skills/.
# Only skills with a SKILL.md are synced (deprecated skills without one are skipped).
# Scripts, venvs, data, and other files remain in the canonical skills/ directory.

echo ""
echo "── Syncing skills ──"

# Clean previous generated skills to remove stale entries
rm -rf "$CLAUDE_SKILLS_DIR" "$OPENCODE_SKILLS_DIR"
mkdir -p "$CLAUDE_SKILLS_DIR" "$OPENCODE_SKILLS_DIR"

skill_count=0
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    echo "SKIP $skill_name (no SKILL.md)"
    continue
  fi

  # Create target directories and copy SKILL.md
  mkdir -p "$CLAUDE_SKILLS_DIR/$skill_name"
  mkdir -p "$OPENCODE_SKILLS_DIR/$skill_name"
  cp "$skill_md" "$CLAUDE_SKILLS_DIR/$skill_name/SKILL.md"
  cp "$skill_md" "$OPENCODE_SKILLS_DIR/$skill_name/SKILL.md"

  # Also copy supplementary docs if they exist (PROMPTS.md, STRATEGY.md, RULES.md, etc.)
  for extra in PROMPTS.md STRATEGY.md RULES.md io_contract.md; do
    if [[ -f "$skill_dir/$extra" ]]; then
      cp "$skill_dir/$extra" "$CLAUDE_SKILLS_DIR/$skill_name/$extra"
      cp "$skill_dir/$extra" "$OPENCODE_SKILLS_DIR/$skill_name/$extra"
    fi
  done

  # Copy JSON schema files (e.g., cluster_mapping_schema.json)
  for json_file in "$skill_dir"/*.json; do
    if [[ -f "$json_file" ]]; then
      cp "$json_file" "$CLAUDE_SKILLS_DIR/$skill_name/"
      cp "$json_file" "$OPENCODE_SKILLS_DIR/$skill_name/"
    fi
  done

  echo "OK  $skill_name"
  skill_count=$((skill_count + 1))
done

# ─── Codex Sync ────────────────────────────────────────────────────────────────
# Codex uses AGENTS.md files placed in directories (scoped to that subtree).
# No YAML frontmatter — plain text only. Deeper AGENTS.md files take precedence.
#
# Generated:
#   agents/AGENTS.md       — Combined agent system prompts (plain text)
#   skills/*/AGENTS.md     — Skill instructions (SKILL.md content, plain text)

echo ""
echo "── Syncing Codex AGENTS.md ──"

# ── agents/AGENTS.md — combined agent definitions ──
{
  echo "# Agent Definitions"
  echo ""
  echo "This directory contains the canonical agent definitions for the project."
  echo "Each .md file defines one agent's system prompt."
  echo ""
  for agent in "${AGENTS[@]}"; do
    src="$SOURCE_DIR/$agent.md"
    [[ -f "$src" ]] || continue
    echo "---"
    echo ""
    extract_body "$src"
    echo ""
  done
} > "$SOURCE_DIR/AGENTS.md"
echo "OK  agents/AGENTS.md"

# ── skills/*/AGENTS.md — per-skill instructions ──
codex_skill_count=0
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    continue
  fi

  # Copy SKILL.md content as AGENTS.md (strip any frontmatter if present)
  # Most SKILL.md files don't have frontmatter, but handle it defensively
  if head -1 "$skill_md" | grep -q '^---$'; then
    extract_body "$skill_md" > "$skill_dir/AGENTS.md"
  else
    cp "$skill_md" "$skill_dir/AGENTS.md"
  fi

  codex_skill_count=$((codex_skill_count + 1))
done
echo "OK  skills/*/AGENTS.md ($codex_skill_count skills)"

echo ""
echo "Sync complete. Generated:"
echo "  Claude Code: $CLAUDE_DIR/ , $CLAUDE_SKILLS_DIR/ ($skill_count skills)"
echo "  OpenCode:    $OPENCODE_DIR/ , $OPENCODE_SKILLS_DIR/ ($skill_count skills)"
echo "  Codex:       agents/AGENTS.md , skills/*/AGENTS.md ($codex_skill_count skills)"
echo ""
echo "Note: Root AGENTS.md and CLAUDE.md are manually maintained."
