#!/bin/bash
# Full self-contained API test script
BASE="http://localhost:3000"
H2="Content-Type: application/json"

# Step 1: Login (try both passwords since change-password test may have changed it)
echo "Logging in..."
RESP=$(curl -s -X POST "$BASE/api/v1/auth/login" -H "$H2" -d '{"phone":"9876543210","password":"Test@12345"}')
echo "$RESP" | python3 -c "import sys,json;json.load(sys.stdin)['data']" 2>/dev/null
if [ $? -ne 0 ]; then
  RESP=$(curl -s -X POST "$BASE/api/v1/auth/login" -H "$H2" -d '{"phone":"9876543210","password":"Test@1234"}')
  CURRENT_PWD="Test@1234"
else
  CURRENT_PWD="Test@12345"
fi
TOKEN=$(echo $RESP | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['tokens']['accessToken'])")
SHOP=$(echo $RESP | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['shops'][0]['_id'])")
REFRESH=$(echo $RESP | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['tokens']['refreshToken'])")
H1="Authorization: Bearer $TOKEN"

# Step 2: Get resource IDs
CUST=$(curl -s "$BASE/api/v1/shops/$SHOP/customers" -H "$H1" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['customers'][0]['_id'])")
PROD=$(curl -s "$BASE/api/v1/shops/$SHOP/products" -H "$H1" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['products'][0]['_id'])")
ENTRY=$(curl -s "$BASE/api/v1/shops/$SHOP/ledger" -H "$H1" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['entries'][0]['_id'])")
REM=$(curl -s "$BASE/api/v1/shops/$SHOP/reminders" -H "$H1" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['reminders'][0]['_id'])")

echo "SHOP=$SHOP CUST=$CUST PROD=$PROD ENTRY=$ENTRY REM=$REM"
echo ""

PASS=0; FAIL=0; FAILED_LIST=""

test_api() {
  local METHOD=$1; local URL=$2; local DATA=$3; local DESC=$4
  local BODY
  if [ -n "$DATA" ]; then
    BODY=$(curl -s -w "\n%{http_code}" -X "$METHOD" "$BASE$URL" -H "$H1" -H "$H2" -d "$DATA" 2>&1)
  else
    BODY=$(curl -s -w "\n%{http_code}" -X "$METHOD" "$BASE$URL" -H "$H1" 2>&1)
  fi
  local CODE=$(echo "$BODY" | tail -1)
  local RESP_BODY=$(echo "$BODY" | sed '$d')
  
  if [[ "$CODE" =~ ^(200|201|204)$ ]]; then
    echo "  ✅ $CODE  $METHOD $URL  ($DESC)"
    PASS=$((PASS+1))
  else
    local MSG=$(echo "$RESP_BODY" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('message','')[:80])" 2>/dev/null || echo "parse-err")
    echo "  ❌ $CODE  $METHOD $URL  ($DESC) → $MSG"
    FAIL=$((FAIL+1))
    FAILED_LIST="$FAILED_LIST\n  ❌ $CODE $METHOD $URL ($DESC) → $MSG"
  fi
}

echo "========================================="
echo "  KhataSetu Full API Test"
echo "========================================="
echo ""

# ─── AUTH ───
echo "── AUTH ──"
test_api GET  "/health" "" "Health check"
test_api POST "/api/v1/auth/login" "{\"phone\":\"9876543210\",\"password\":\"$CURRENT_PWD\"}" "Login"
test_api GET  "/api/v1/auth/me" "" "Get profile"
test_api POST "/api/v1/auth/send-otp" '{"phone":"9876543210","type":"verify"}' "Send OTP"
test_api POST "/api/v1/auth/verify-otp" '{"phone":"9876543210","otp":"123456"}' "Verify OTP"
test_api POST "/api/v1/auth/refresh-token" "{\"refreshToken\":\"$REFRESH\"}" "Refresh token"
test_api POST "/api/v1/auth/change-password" "{\"currentPassword\":\"$CURRENT_PWD\",\"newPassword\":\"Test@12345\",\"confirmPassword\":\"Test@12345\"}" "Change password"
test_api POST "/api/v1/auth/fcm-token" '{"token":"test_fcm_token_123","deviceId":"test_device"}' "Register FCM token"
test_api POST "/api/v1/auth/logout" "" "Logout"
test_api POST "/api/v1/auth/logout-all" "" "Logout all"

# Refresh token since we logged out (password may have changed from change-password test)
RESP=$(curl -s -X POST "$BASE/api/v1/auth/login" -H "$H2" -d '{"phone":"9876543210","password":"Test@12345"}')
TOKEN=$(echo $RESP | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['tokens']['accessToken'])" 2>/dev/null)
if [ -z "$TOKEN" ]; then
  RESP=$(curl -s -X POST "$BASE/api/v1/auth/login" -H "$H2" -d '{"phone":"9876543210","password":"Test@1234"}')
  TOKEN=$(echo $RESP | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['tokens']['accessToken'])")
fi
H1="Authorization: Bearer $TOKEN"

echo ""

# ─── SHOPS ───
echo "── SHOPS ──"
test_api GET  "/api/v1/shops" "" "List shops"
test_api GET  "/api/v1/shops/$SHOP" "" "Get shop"
test_api PATCH "/api/v1/shops/$SHOP" '{"name":"Test Shop"}' "Update shop"
test_api GET  "/api/v1/shops/$SHOP/employees" "" "List employees"
test_api POST "/api/v1/shops/$SHOP/employees" '{"phone":"6654321099","name":"Emp2","role":"cashier","permissions":["view_customers"]}' "Add employee"
test_api PATCH "/api/v1/shops/$SHOP/settings" '{"currency":"INR","defaultCreditLimit":1000}' "Update settings"
echo ""

# ─── CUSTOMERS ───
echo "── CUSTOMERS ──"
test_api GET  "/api/v1/shops/$SHOP/customers" "" "List customers"
test_api GET  "/api/v1/shops/$SHOP/customers/search?q=Ramesh" "" "Search customers"
test_api GET  "/api/v1/shops/$SHOP/customers/$CUST" "" "Get customer"
test_api GET  "/api/v1/shops/$SHOP/customers/$CUST/stats" "" "Customer stats"
test_api PATCH "/api/v1/shops/$SHOP/customers/$CUST" '{"creditLimit":5000}' "Update customer"
echo ""

# ─── LEDGER ───
echo "── LEDGER ──"
test_api POST "/api/v1/shops/$SHOP/ledger" "{\"customerId\":\"$CUST\",\"type\":\"credit\",\"amount\":100,\"description\":\"Test\"}" "Create entry"
test_api GET  "/api/v1/shops/$SHOP/ledger" "" "List entries"
test_api GET  "/api/v1/shops/$SHOP/ledger/summary" "" "Ledger summary"
test_api GET  "/api/v1/shops/$SHOP/ledger/$ENTRY" "" "Get entry"
test_api GET  "/api/v1/shops/$SHOP/ledger/customers/$CUST" "" "Customer ledger"
test_api PATCH "/api/v1/shops/$SHOP/ledger/$ENTRY" '{"description":"Updated"}' "Update entry"
test_api DELETE "/api/v1/shops/$SHOP/ledger/$ENTRY" '{"reason":"test"}' "Delete entry"
echo ""

# ─── PRODUCTS ───
echo "── PRODUCTS ──"
test_api GET  "/api/v1/shops/$SHOP/products" "" "List products"
test_api GET  "/api/v1/shops/$SHOP/products/categories" "" "Categories"
test_api GET  "/api/v1/shops/$SHOP/products/low-stock" "" "Low stock"
test_api GET  "/api/v1/shops/$SHOP/products/barcode/1234567890" "" "By barcode"
test_api GET  "/api/v1/shops/$SHOP/products/$PROD" "" "Get product"
test_api PATCH "/api/v1/shops/$SHOP/products/$PROD" '{"sellingPrice":30}' "Update product"
test_api POST "/api/v1/shops/$SHOP/products/$PROD/stock" '{"type":"stock_in","quantity":10,"unitPrice":20,"notes":"restock"}' "Adjust stock"
test_api GET  "/api/v1/shops/$SHOP/products/$PROD/stock-history" "" "Stock history"
echo ""

# ─── REMINDERS ───
echo "── REMINDERS ──"
test_api GET  "/api/v1/shops/$SHOP/reminders" "" "List reminders"
test_api GET  "/api/v1/shops/$SHOP/reminders/today" "" "Today reminders"
test_api GET  "/api/v1/shops/$SHOP/reminders/$REM" "" "Get reminder"
test_api PATCH "/api/v1/shops/$SHOP/reminders/$REM" '{"title":"Updated"}' "Update reminder"
test_api POST "/api/v1/shops/$SHOP/reminders/$REM/acknowledge" "" "Acknowledge"
test_api POST "/api/v1/shops/$SHOP/reminders/$REM/snooze" '{"snoozeUntil":"2026-03-18T10:00:00.000Z"}' "Snooze"
test_api POST "/api/v1/shops/$SHOP/reminders/$REM/cancel" "" "Cancel"
test_api POST "/api/v1/shops/$SHOP/reminders/bulk" "{\"customerIds\":[\"$CUST\"],\"type\":\"follow_up\",\"title\":\"Bulk1\",\"scheduledAt\":\"2026-04-01T08:00:00.000Z\"}" "Bulk create"
echo ""

# ─── REPORTS ───
echo "── REPORTS ──"
test_api GET "/api/v1/shops/$SHOP/reports/dashboard" "" "Dashboard"
test_api GET "/api/v1/shops/$SHOP/reports/ledger?startDate=2026-03-01&endDate=2026-03-31" "" "Ledger report"
test_api GET "/api/v1/shops/$SHOP/reports/inventory" "" "Inventory report"
test_api GET "/api/v1/shops/$SHOP/reports/customers" "" "Customer report"
test_api GET "/api/v1/shops/$SHOP/reports/export/ledger?startDate=2026-03-01&endDate=2026-03-31&format=csv" "" "Export ledger"
echo ""

# ─── SYNC ───
echo "── SYNC ──"
test_api GET  "/api/v1/shops/$SHOP/sync/status" "" "Sync status"
test_api GET  "/api/v1/shops/$SHOP/sync/changes?lastSyncAt=2026-03-01T00:00:00.000Z" "" "Get changes"
test_api POST "/api/v1/shops/$SHOP/sync" '{"items":[],"deviceId":"test_device"}' "Sync data"
test_api POST "/api/v1/shops/$SHOP/sync/resolve" '{"offlineId":"test-offline-id","resolution":"server_wins"}' "Resolve conflict"

echo ""
echo "========================================="
echo "  RESULTS: $PASS passed, $FAIL failed out of $((PASS+FAIL))"
echo "========================================="
if [ $FAIL -gt 0 ]; then
  echo ""
  echo "  FAILED APIs:"
  echo -e "$FAILED_LIST"
fi
echo ""
