#!/usr/bin/env bash
# deploy.sh – Deploy Access Booster infrastructure to Azure
#
# Prerequisites:
#   1. Run `az login` to authenticate with Azure.
#   2. Run `az account set --subscription <SUBSCRIPTION_ID>` if you have
#      multiple subscriptions and want to target a specific one.
#
# Usage:
#   bash scripts/deploy.sh [--location <azure-region>] [--subscription <id>]

set -euo pipefail

LOCATION="eastus"
SUBSCRIPTION=""

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --location)
      LOCATION="$2"
      shift 2
      ;;
    --subscription)
      SUBSCRIPTION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--location <azure-region>] [--subscription <id>]"
      exit 1
      ;;
  esac
done

# ── Validate az login ─────────────────────────────────────────────────────────
echo "Verifying Azure login..."
if ! az account show --output none 2>/dev/null; then
  echo "ERROR: Not logged in to Azure. Please run 'az login' first."
  exit 1
fi

if [[ -n "$SUBSCRIPTION" ]]; then
  echo "Setting subscription to: $SUBSCRIPTION"
  az account set --subscription "$SUBSCRIPTION"
fi

CURRENT_SUB=$(az account show --query "name" -o tsv)
echo "Using subscription: $CURRENT_SUB"

# ── Collect SQL administrator password without echoing it ─────────────────────
while true; do
  read -r -s -p "Enter a strong Azure SQL administrator password (16+ characters, upper/lowercase, number, and symbol): " SQL_ADMIN_PASSWORD
  echo ""
  if [[ ${#SQL_ADMIN_PASSWORD} -ge 16 &&
        "$SQL_ADMIN_PASSWORD" =~ [A-Z] &&
        "$SQL_ADMIN_PASSWORD" =~ [a-z] &&
        "$SQL_ADMIN_PASSWORD" =~ [0-9] &&
        "$SQL_ADMIN_PASSWORD" =~ [^A-Za-z0-9] ]]; then
    break
  fi
  echo "ERROR: Password does not meet the required strength. Please try again."
done

# ── Generate timestamp ────────────────────────────────────────────────────────
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
DEPLOYMENT_NAME="access-booster-${TIMESTAMP}"

echo ""
echo "Starting deployment: ${DEPLOYMENT_NAME}"
echo "  Location : ${LOCATION}"
echo ""

# ── Run Bicep deployment ──────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_FILE="${SCRIPT_DIR}/../infra/main.bicep"

DEPLOY_OUTPUT=$(mktemp)
chmod 600 "${DEPLOY_OUTPUT}"
trap 'rm -f "${DEPLOY_OUTPUT}"; unset SQL_ADMIN_PASSWORD' EXIT

az deployment sub create \
  --name        "${DEPLOYMENT_NAME}" \
  --location    "${LOCATION}" \
  --template-file "${BICEP_FILE}" \
  --parameters  timestamp="${TIMESTAMP}" location="${LOCATION}" sqlAdminPassword="${SQL_ADMIN_PASSWORD}" \
  --output      json \
  > "${DEPLOY_OUTPUT}"

echo ""
echo "✅ Deployment complete."
echo ""

# ── Print outputs ─────────────────────────────────────────────────────────────
if ! jq -e '.properties.outputs' "${DEPLOY_OUTPUT}" > /dev/null 2>&1; then
  echo "ERROR: Deployment output is missing expected fields. Check the Azure portal for details."
  cat "${DEPLOY_OUTPUT}"
  exit 1
fi

RG=$(jq -r '.properties.outputs.resourceGroupName.value' "${DEPLOY_OUTPUT}")
PLAN=$(jq -r '.properties.outputs.appServicePlanName.value' "${DEPLOY_OUTPUT}")
APP=$(jq -r '.properties.outputs.appServiceName.value' "${DEPLOY_OUTPUT}")
HOST=$(jq -r '.properties.outputs.appServiceDefaultHostName.value' "${DEPLOY_OUTPUT}")

echo "Resource Group  : ${RG}"
echo "App Service Plan: ${PLAN}"
echo "App Service     : ${APP}"
echo "Default URL     : https://${HOST}"
