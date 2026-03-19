#!/bin/bash
# Deploy Plattr OS edge functions to Plattr Supabase
# Project ref: yamjjiwifuiuhxzlnqzx
# Run from repo root; supabase/ is at repo root

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PROJECT_REF="${SUPABASE_PROJECT_REF:-yamjjiwifuiuhxzlnqzx}"

echo "Deploying Plattr functions to project $PROJECT_REF..."

npx supabase functions deploy pos-offline-sync --project-ref "$PROJECT_REF"
npx supabase functions deploy pos-login-bootstrap --project-ref "$PROJECT_REF"
npx supabase functions deploy printnode-secure --project-ref "$PROJECT_REF"
npx supabase functions deploy update-order-status-secure --project-ref "$PROJECT_REF"
npx supabase functions deploy mark-order-payment-received --project-ref "$PROJECT_REF"
npx supabase functions deploy loyalty-whatsapp-send --project-ref "$PROJECT_REF"
npx supabase functions deploy whatsapp-automation-runner --project-ref "$PROJECT_REF"
npx supabase functions deploy ai-upsell-suggest --project-ref "$PROJECT_REF"

echo "Done. Ensure these secrets are set in Supabase Dashboard:"
echo "  - WHATSAPP_ACCESS_TOKEN (for loyalty-whatsapp-send)"
echo "  - WHATSAPP_PHONE_NUMBER_ID (for loyalty-whatsapp-send)"
echo "  - PRINTNODE_API_KEY (for printnode-secure)"
echo "  - ALLOWED_ORIGINS (optional, comma-separated)"
