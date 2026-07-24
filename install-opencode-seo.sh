#!/usr/bin/env bash
set -euo pipefail
# install-opencode-seo.sh – Install Claude SEO skills for OpenCode
# Source: https://github.com/AgriciDaniel/claude-seo

main() {
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'

    SKILLS_DIR="${HOME}/.config/opencode/skills"
    REPO_URL="https://github.com/AgriciDaniel/claude-seo"
    REPO_TAG="${CLAUDE_SEO_TAG:-v2.2.4}"

    echo -e "${GREEN}[+] Installing Claude SEO for OpenCode...${NC}"

    command -v git >/dev/null 2>&1 || { echo -e "${RED}✗ Git required.${NC}"; exit 1; }
    command -v python3 >/dev/null 2>&1 || { echo -e "${RED}✗ Python 3.10+ required.${NC}"; exit 1; }

    mkdir -p "${SKILLS_DIR}"
    TEMP_DIR=$(mktemp -d)
    cleanup() { rm -rf -- "${TEMP_DIR}"; }
    trap cleanup EXIT

    echo "  → Downloading claude-seo (${REPO_TAG})..."
    git clone --depth 1 --branch "${REPO_TAG}" "${REPO_URL}" "${TEMP_DIR}/claude-seo" 2>/dev/null

    OPNCODE_HOME="${SKILLS_DIR}/seo"
    LAUNCHER="${OPNCODE_HOME}/bin/claude-seo"

    echo "  → Copying skills..."
    for skill_dir in "${TEMP_DIR}/claude-seo/skills/"*/; do
        skill_name=$(basename "$skill_dir")
        target="${SKILLS_DIR}/${skill_name}"
        mkdir -p "$target"

        find "$skill_dir" -mindepth 1 -not -name '*.md' | while read -r src_item; do
            rel="${src_item#$skill_dir}"
            dst="$target/$rel"
            if [ -d "$src_item" ]; then
                mkdir -p "$dst"
                cp -r "$src_item"/* "$dst/" 2>/dev/null || true
            else
                mkdir -p "$(dirname "$dst")"
                cp "$src_item" "$dst"
            fi
        done

        find "$skill_dir" -name '*.md' | while read -r src_md; do
            rel="${src_md#$skill_dir}"
            dst="$target/$rel"
            mkdir -p "$(dirname "$dst")"
            sed 's|\bclaude-seo run\b|'"$LAUNCHER"' run|g; s|\bclaude-seo setup\b|'"$LAUNCHER"' setup|g; s|\bclaude-seo doctor\b|'"$LAUNCHER"' doctor|g' "$src_md" > "$dst"
        done
    done

    echo "  → Installing scripts and runtime..."
    mkdir -p "${OPNCODE_HOME}/scripts" "${OPNCODE_HOME}/bin" "${OPNCODE_HOME}/schema" "${OPNCODE_HOME}/pdf" "${OPNCODE_HOME}/data"

    for py_file in "${TEMP_DIR}/claude-seo/scripts/"*.py; do
        base=$(basename "$py_file")
        sed 's|\bclaude-seo run\b|'"$LAUNCHER"' run|g; s|\bclaude-seo setup\b|'"$LAUNCHER"' setup|g; s|\bclaude-seo doctor\b|'"$LAUNCHER"' doctor|g' "$py_file" > "${OPNCODE_HOME}/scripts/$base"
    done

    cp "${TEMP_DIR}/claude-seo/bin/claude-seo" "${OPNCODE_HOME}/bin/claude-seo"
    chmod +x "${OPNCODE_HOME}/bin/claude-seo"

    [ -d "${TEMP_DIR}/claude-seo/schema" ] && cp -r "${TEMP_DIR}/claude-seo/schema/"* "${OPNCODE_HOME}/schema/" 2>/dev/null || true
    [ -d "${TEMP_DIR}/claude-seo/pdf" ] && cp -r "${TEMP_DIR}/claude-seo/pdf/"* "${OPNCODE_HOME}/pdf/" 2>/dev/null || true
    [ -d "${TEMP_DIR}/claude-seo/data" ] && cp -r "${TEMP_DIR}/claude-seo/data/"* "${OPNCODE_HOME}/data/" 2>/dev/null || true
    [ -f "${TEMP_DIR}/claude-seo/requirements.txt" ] && cp "${TEMP_DIR}/claude-seo/requirements.txt" "${OPNCODE_HOME}/requirements.txt"

    echo "  → Setting up Python runtime..."
    export CLAUDE_SEO_PYTHON="$(which python3)"
    "${OPNCODE_HOME}/bin/claude-seo" setup 2>&1 || {
        echo -e "${YELLOW}⚠ Runtime setup had warnings, but skills may still work.${NC}"
    }

    echo "  → Installing Playwright Chromium..."
    "${OPNCODE_HOME}/bin/claude-seo" doctor 2>&1 || true

    echo -e "${GREEN}✓ Claude SEO installed for OpenCode (25 skills)${NC}"
    echo "  Skills location: ${SKILLS_DIR}/seo*/"
    echo "  Runtime: ${LAUNCHER}"
}

main "$@"
