#!/usr/bin/env bash


set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

VENV_DIR="$(pwd)/venv"
PACKAGE="ibm-watsonx-orchestrate"
REQUIRED_PY_MINOR=11   # need >= 3.11

fix_pip_index() {
    local current
    current=$(pip config get global.index-url 2>/dev/null || true)
    if [[ "$current" == *"pypi.python.org"* ]]; then
        warn "pip index-url is set to the OLD mirror ($current). Fixing..."
        pip config set global.index-url https://pypi.org/simple/
        success "pip index-url updated to https://pypi.org/simple/"
    fi
}

ensure_uv() {
    if command -v uv &>/dev/null; then
        success "uv found: $(uv --version)"
        return
    fi

    info "uv not found — installing via the official installer (no sudo needed)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Add to PATH for this session
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    if ! command -v uv &>/dev/null; then
        # Try snap as fallback
        if command -v snap &>/dev/null; then
            warn "curl install failed, trying snap..."
            snap install astral-uv --classic 2>/dev/null || true
            export PATH="/snap/bin:$PATH"
        fi
    fi

    command -v uv &>/dev/null || error "Could not install uv. Please install it manually: https://docs.astral.sh/uv/getting-started/installation/"
    success "uv installed: $(uv --version)"
}

check_python() {
    local sys_minor
    sys_minor=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null || echo "0")

    if (( sys_minor >= REQUIRED_PY_MINOR )); then
        success "System Python 3.${sys_minor} meets the >= 3.11 requirement."
    else
        warn "System Python is 3.${sys_minor} — too old. uv will download Python 3.11 automatically."
    fi
}


create_venv() {
    if [[ -d "$VENV_DIR" ]]; then
        info "Removing existing venv at $VENV_DIR ..."
        rm -rf "$VENV_DIR"
    fi

    info "Creating Python 3.11 virtual environment at $VENV_DIR ..."
    uv venv --python 3.11 "$VENV_DIR"
    success "Virtual environment created."
}

install_package() {
    info "Installing $PACKAGE (this may take a minute)..."

    # uv respects the activated venv; activate it inline for this step
    # shellcheck disable=SC1091
    source "$VENV_DIR/bin/activate"

    uv pip install "$PACKAGE"

    success "$PACKAGE installed successfully."
}

verify() {
    info "Verifying installation..."

    # Python import check
    "$VENV_DIR/bin/python" -c "import ibm_watsonx_orchestrate; print('Python import: OK')"

    # CLI check
    local version_output
    version_output=$("$VENV_DIR/bin/orchestrate" --version 2>&1 | head -1)
    success "orchestrate CLI: $version_output"
}


print_next_steps() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ibm-watsonx-orchestrate is ready!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Activate the environment:"
    echo -e "    ${CYAN}source $(pwd)/venv/bin/activate${NC}"
    echo ""
    echo "  Then use the CLI:"
    echo -e "    ${CYAN}orchestrate --help${NC}"
    echo ""
}

main() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  ibm-watsonx-orchestrate installer${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    echo ""

    fix_pip_index
    ensure_uv
    check_python
    create_venv
    install_package
    verify
    print_next_steps
}

main
