# https://juseljuk.github.io/bobchestrate-workshop/part1-setup/quiz/

#!/usr/bin/env bash
# =============================================================================
# add_env.sh
#
# Adds and activates a watsonx Orchestrate SaaS environment for the ADK.
#
# Usage:
#   bash add_env.sh --name <env-name> --url <instance-url> --api-key <api-key>
#
# Example:
#   bash add_env.sh --name my-prod --url https://api.example.ibm.com --api-key abc123
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Parse arguments ──────────────────────────────────────────────────────────
ENV_NAME=""
ENV_URL=""
API_KEY=""

usage() {
    echo "Usage: bash add_env.sh --name <env-name> --url <instance-url> --api-key <api-key>"
    echo ""
    echo "  --name     Short name for this environment (e.g. my-prod)"
    echo "  --url      Full URL of your watsonx Orchestrate instance"
    echo "  --api-key  Your IBM Cloud / WXO API key"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)    ENV_NAME="$2";  shift 2 ;;
        --url)     ENV_URL="$2";   shift 2 ;;
        --api-key) API_KEY="$2";   shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$ENV_NAME" ]] && error "--name is required"
[[ -z "$ENV_URL"  ]] && error "--url is required"
[[ -z "$API_KEY"  ]] && error "--api-key is required"

# ── Locate the venv ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

if [[ ! -f "$VENV_DIR/bin/orchestrate" ]]; then
    error "orchestrate CLI not found at $VENV_DIR/bin/orchestrate.\nRun install_orchestrate.sh first."
fi

# Activate the venv for this session
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# ── Step 1: Add the environment ───────────────────────────────────────────────
info "Adding environment '$ENV_NAME' → $ENV_URL ..."
orchestrate env add --name "$ENV_NAME" --url "$ENV_URL"
success "Environment '$ENV_NAME' added."

# ── Step 2: Activate the environment with the API key ────────────────────────
info "Activating environment '$ENV_NAME' ..."
orchestrate env activate "$ENV_NAME" --api-key "$API_KEY"
success "Environment '$ENV_NAME' is now active."

# ── Step 3: Confirm ──────────────────────────────────────────────────────────
echo ""
info "Current environments:"
orchestrate env list 2>&1

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Environment ready!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Activate the venv and run commands:"
echo -e "    ${CYAN}source $VENV_DIR/bin/activate${NC}"
echo -e "    ${CYAN}orchestrate agents list${NC}"
echo ""
