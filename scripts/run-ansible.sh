#!/bin/bash
# XAI Ansible runner
# Usage: ./run-ansible.sh <command>
#
# Commands:
#   deploy         - Deploy all XAI nodes
#   update         - Rolling code update
#   health         - Health check all nodes
#   rollback       - Rollback to previous version
#   backup         - Backup node keys

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"
INVENTORY="$ANSIBLE_DIR/inventory/testnet.yml"
PLAYBOOKS="$ANSIBLE_DIR/playbooks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << EOF
XAI Ansible Runner

Usage: $0 <command> [options]

Commands:
  deploy              Deploy all XAI nodes
  deploy-services     Deploy XAI supporting services
  update              Rolling code update from git
  health              Health check all nodes
  rollback            Rollback to previous git commit
  backup              Backup node keys (STORE SECURELY!)
  check               Dry-run to see what would change

Options:
  --limit <node>      Target specific node (xai_node1, xai_node2, etc.)

Examples:
  $0 deploy                     Deploy all XAI nodes
  $0 update                     Update code on all nodes
  $0 update --limit xai_node1   Update single node
  $0 health                     Check all nodes
  $0 rollback                   Rollback all nodes

EOF
}

run_playbook() {
    local playbook=$1
    shift
    log_info "Running: ansible-playbook -i $INVENTORY $playbook $*"
    ansible-playbook -i "$INVENTORY" "$playbook" "$@"
}

case "${1:-help}" in
    deploy)
        shift
        log_info "Deploying XAI nodes..."
        run_playbook "$PLAYBOOKS/deploy-nodes.yml" "$@"
        ;;

    deploy-services)
        shift
        log_info "Deploying XAI services..."
        run_playbook "$PLAYBOOKS/deploy-services.yml" "$@"
        ;;

    update)
        shift
        log_info "Running rolling code update..."
        run_playbook "$PLAYBOOKS/update-code.yml" "$@"
        ;;

    health)
        shift
        log_info "Running health checks..."
        run_playbook "$PLAYBOOKS/health-check.yml" "$@"
        ;;

    rollback)
        shift
        log_warn "Rolling back XAI nodes to previous version..."
        read -p "Are you sure? (y/N) " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            run_playbook "$PLAYBOOKS/rollback.yml" "$@"
        else
            log_info "Rollback cancelled"
        fi
        ;;

    backup)
        shift
        log_warn "Backing up XAI node keys..."
        log_warn "IMPORTANT: Secure these files immediately after backup!"
        run_playbook "$PLAYBOOKS/backup-keys.yml" "$@"
        ;;

    check)
        shift
        log_info "Dry-run check (no changes will be made)..."
        run_playbook "$PLAYBOOKS/deploy-nodes.yml" --check --diff "$@"
        ;;

    help|--help|-h)
        show_help
        ;;

    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

log_info "Done!"
