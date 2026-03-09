# BookVisually - Detailed Use Cases & Visual Workflows

## Product Vision

BookVisually transforms traditional bookkeeping into an **interactive visual experience** where users see their business finances as a **living diagram**. Instead of spreadsheets and forms, users interact with **nodes** (resources, accounts, transactions) and watch **money flow** in real-time through visual connections.

---

## Core Concept: The Visual Canvas

The main interface is a **React Flow canvas** where:
- **Nodes** represent entities (accounts, resources, bills, expenses)
- **Edges** represent money flow and relationships
- **Colors** indicate status (green = healthy, yellow = warning, red = critical)
- **Animations** show money moving between nodes
- **Totals** update in real-time as transactions occur

---

## Real-World Scenario: Small Construction Business

**Business:** ABC Construction  
**Owner:** Sarah  
**Challenge:** Track materials, equipment, bills, and cash flow visually

---

## Day 1: Setting Up the Business

### Scenario 1.1: Initial Setup - Creating the Financial Foundation

**Sarah's Goal:** Set up her business accounts and see them on the canvas

**Visual Workflow:**
1. Sarah opens BookVisually - sees empty canvas
2. Clicks "Add Account" button
3. Modal appears: "What type of account?"
   - Cash at Hand (💵)
   - Bank Account (🏦)
   - Funding Line (💰)
4. Sarah selects "Bank Account"
5. Fills in: "Main Business Account", "First National Bank", "Account #1234"
6. Clicks "Create"
7. **Visual Result:** A blue bank node appears on canvas showing:
   ```
   🏦 Main Business Account
   Balance: $0.00
   First National Bank
   ```

8. Sarah repeats for "Petty Cash" (cash_at_hand)
9. **Visual Result:** Two nodes now visible on canvas

**Backend API Calls:**
```
POST /api/accounts
{
  "name": "Main Business Account",
  "account_type": "bank_account",
  "bank_name": "First National Bank",
  "account_number": "1234"
}

POST /api/accounts
{
  "name": "Petty Cash",
  "account_type": "cash_at_hand"
}
```

**Canvas State After:**
```
[🏦 Main Business Account]    [💵 Petty Cash]
   Balance: $0.00                Balance: $0.00
```

---

### Scenario 1.2: Initial Investment - Watching Money Flow

**Sarah's Goal:** Record her $50,000 initial investment and see it flow into her bank account

**Visual Workflow:**
1. Sarah clicks the "Main Business Account" node
2. Node highlights, action menu appears:
   - 💰 Deposit
   - 💸 Withdraw
   - 🔄 Transfer
   - 📊 View History
3. Sarah clicks "💰 Deposit"
4. Modal appears: "Record Deposit"
   - Amount: $50,000
   - Description: "Initial investment"
   - Date: [today]
5. Sarah clicks "Record"
6. **Visual Animation:**
   - Money icon (💵) appears from top of screen
   - Flows down into the bank account node
   - Node pulses green
   - Balance updates: $0.00 → $50,000.00
7. Transaction appears in activity feed on right side

**Backend API Call:**
```
POST /api/transactions/deposit
{
  "to_account_id": "bank-uuid",
  "amount": 50000.00,
  "description": "Initial investment",
  "transaction_date": "2026-03-08T10:00:00Z"
}
```

**Canvas State After:**
```
[🏦 Main Business Account]    [💵 Petty Cash]
   Balance: $50,000.00           Balance: $0.00
   ↑ +$50,000 (Investment)
```

---

## Day 2: Setting Up Resources

### Scenario 2.1: Adding Resources - Building the Resource Network

**Sarah's Goal:** Add the materials and equipment she needs to track

**Visual Workflow:**
1. Sarah clicks "Add Resource" button
2. Modal: "What are you tracking?"
   - 📦 Supply (inventory that gets used up)
   - 🏗️ Asset (equipment, vehicles)
   - 📅 Subscription (recurring services)
   - 📄 Utility (bills with meter readings)
3. Sarah selects "📦 Supply"
4. Form appears:
   - Name: "Cement"
   - Unit: "bags"
   - Alert when below: 20 bags
   - Current stock: 0
5. Clicks "Create"
6. **Visual Result:** Orange supply node appears:
   ```
   📦 Cement
   Stock: 0 bags
   Alert: < 20 bags
   Status: 🔴 Out of Stock
   ```

7. Sarah adds more resources:
   - 📦 "Generator Fuel" (liters)
   - 🏗️ "Concrete Mixer" (asset, purchased 2025-01-15, $5,000)
   - 📄 "Water Bill" (utility)

**Backend API Calls:**
```
POST /api/resources
{
  "name": "Cement",
  "resource_category": "supply",
  "default_unit_of_measure": "bags",
  "supply_properties": {
    "out_of_stock_alert_quantity": 20,
    "issues_out_of_stock_alerts": true,
    "current_stock_quantity": 0
  }
}

POST /api/resources
{
  "name": "Concrete Mixer",
  "resource_category": "asset",
  "asset_properties": {
    "purchase_date": "2025-01-15",
    "purchase_cost": 5000.00,
    "current_value": 5000.00,
    "depreciation_method": "straight_line",
    "status": "in_use"
  }
}
```

**Canvas State After:**
```
Accounts Section:
[🏦 Main Business]  [💵 Petty Cash]
   $50,000.00          $0.00

Resources Section:
[📦 Cement]        [📦 Generator Fuel]  [🏗️ Concrete Mixer]  [📄 Water Bill]
  0 bags 🔴          0 L 🔴              $5,000 value         $0 unpaid
```

---

## Day 3: First Purchase - The Complete Flow

### Scenario 3.1: Buying Cement - Expense → Stock → Money Flow

**Sarah's Goal:** Buy 100 bags of cement and see the complete transaction flow

**Visual Workflow:**
1. Sarah clicks the "📦 Cement" node
2. Action menu appears:
   - 📥 Purchase (buy more)
   - 📤 Record Usage
   - 📊 View History
3. Sarah clicks "📥 Purchase"
4. Modal: "Record Purchase"
   - Quantity: 100 bags
   - Unit Cost: $8.50 per bag
   - Total: $850.00 (auto-calculated)
   - Paid from: [dropdown] → "Main Business Account"
   - Date: [today]
   - Vendor: "BuildMart"
5. Sarah clicks "Record Purchase"
6. **Visual Animation Sequence:**
   
   **Step 1:** Expense node appears
   ```
   [💳 Expense]
   Cement Purchase
   $850.00
   BuildMart
   ```
   
   **Step 2:** Money flows from bank to expense
   ```
   [🏦 Main Business] ----💸----> [💳 Expense]
      $50,000 → $49,150
   ```
   
   **Step 3:** Stock flows from expense to cement
   ```
   [💳 Expense] ----📦----> [📦 Cement]
                              0 → 100 bags
                              🔴 → 🟢
   ```
   
   **Step 4:** Nodes settle into final state
   - Bank account shows new balance
   - Cement shows new stock level
   - Expense node fades but remains in history
   - Edge connections remain visible (can be toggled)

**Backend API Calls:**
```
POST /api/expenses/with-payment
{
  "resource_id": "cement-uuid",
  "expense_date": "2026-03-10",
  "unit_cost": 8.50,
  "quantity": 100,
  "unit_of_measure": "bags",
  "paid_from_account_id": "bank-uuid",
  "vendor": "BuildMart",
  "description": "Cement purchase"
}

// This triggers:
// 1. Create expense
// 2. Create account transaction (expense payment)
// 3. Create stock movement (purchase)
// 4. Update account balance
// 5. Update stock level
```

**Canvas State After:**
```
[🏦 Main Business]  ----💸----> [💳 Cement Purchase]
   $49,150.00                      $850.00
                                      ↓
                                   [📦 Cement]
                                   100 bags 🟢
```

---

### Scenario 3.2: Using Cement - Tracking Consumption

**Sarah's Goal:** Record using 30 bags of cement on a job

**Visual Workflow:**
1. Sarah clicks "📦 Cement" node
2. Clicks "📤 Record Usage"
3. Modal: "Record Usage"
   - Quantity: 30 bags
   - Used by: "Foundation Team"
   - Project: "Johnson House Foundation"
   - Date: [today]
4. Clicks "Record"
5. **Visual Animation:**
   - 30 bags visually "flow out" of cement node
   - Stock updates: 100 → 70 bags
   - Status stays green (above 20 threshold)
   - Usage record appears in history

**Backend API Call:**
```
POST /api/supplies/cement-uuid/movements/usage
{
  "quantity_change": 30,
  "used_by": "Foundation Team",
  "description": "Johnson House Foundation",
  "movement_date": "2026-03-11"
}
```

**Canvas State After:**
```
[📦 Cement]
  70 bags 🟢
  ↓ -30 bags (Foundation Team)
```

---

## Day 4: Bill Management - The Bill-to-Payment Flow

### Scenario 4.1: Receiving a Water Bill

**Sarah's Goal:** Record a water bill she received (before paying it)

**Visual Workflow:**
1. Sarah clicks "📄 Water Bill" resource node
2. Clicks "📄 Add Bill"
3. Modal: "Record Bill"
   - Bill Date: March 1, 2026
   - Due Date: March 15, 2026
   - Previous Reading: 1500 m³
   - Current Reading: 1750 m³
   - Consumption: 250 m³ (auto-calculated)
   - Rate: $0.30 per m³
   - Total: $75.00 (auto-calculated)
   - Vendor: "City Water Utility"
4. Clicks "Record"
5. **Visual Result:**
   - Bill node appears connected to Water Bill resource
   - Shows as "unpaid" with red indicator
   - Due date countdown visible
   ```
   [📄 Water Bill] ----📋----> [📋 Bill #001]
                                  $75.00 UNPAID
                                  Due: Mar 15 (4 days)
   ```

**Backend API Call:**
```
POST /api/bills
{
  "resource_id": "water-bill-uuid",
  "bill_date": "2026-03-01",
  "due_date": "2026-03-15",
  "previous_reading": 1500,
  "bill_reading": 1750,
  "unit_of_measure": "m³",
  "unit_cost": 0.30,
  "total_amount": 75.00,
  "vendor": "City Water Utility"
}
```

---

### Scenario 4.2: Paying the Bill - Complete Transaction Flow

**Sarah's Goal:** Pay the water bill and see money flow

**Visual Workflow:**
1. Sarah clicks the unpaid bill node
2. Clicks "💰 Pay Bill"
3. Modal: "Pay Bill"
   - Amount: $75.00 (pre-filled)
   - Pay from: [dropdown] → "Main Business Account"
   - Payment Date: [today]
4. Clicks "Pay"
5. **Visual Animation Sequence:**
   
   **Step 1:** Money flows from bank
   ```
   [🏦 Main Business] ----💸----> [📋 Bill #001]
      $49,150 → $49,075              $75.00
   ```
   
   **Step 2:** Bill status changes
   ```
   [📋 Bill #001]
   $75.00 PAID ✅
   Paid: Mar 11
   ```
   
   **Step 3:** Expense record created
   ```
   [💳 Water Bill Payment]
   $75.00
   City Water Utility
   ```

**Backend API Call:**
```
POST /api/bills/bill-uuid/pay
{
  "paid_from_account_id": "bank-uuid",
  "payment_date": "2026-03-11"
}

// This triggers:
// 1. Create expense
// 2. Create account transaction
// 3. Update bill status to "paid"
// 4. Update account balance
// 5. Update utility resource properties
```

---

## Day 5: Dashboard View - The Big Picture

### Scenario 5.1: Morning Overview

**Sarah's Goal:** See her business financial health at a glance

**Visual Workflow:**
1. Sarah opens BookVisually
2. Dashboard view shows:

```
┌─────────────────────────────────────────────────────────┐
│  💰 Total Balance: $49,075.00                           │
│  📊 Cash Flow: +$50,000 in | -$925 out                  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  ⚠️  ALERTS                                              │
│  • Generator Fuel: 🔴 Out of Stock (0 L)                │
│  • Cement: 🟢 70 bags (healthy)                          │
│  • No overdue bills                                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  📅 UPCOMING                                             │
│  • No bills due in next 7 days                           │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  📈 RECENT ACTIVITY                                      │
│  • Mar 11: Paid Water Bill -$75.00                       │
│  • Mar 11: Used 30 bags Cement                           │
│  • Mar 10: Purchased Cement -$850.00                     │
│  • Mar 08: Initial Investment +$50,000.00                │
└─────────────────────────────────────────────────────────┘
```

**Backend API Call:**
```
GET /api/dashboard

Response:
{
  "total_balance": 49075.00,
  "total_cash_in": 50000.00,
  "total_cash_out": 925.00,
  "alerts": {
    "low_stock": [
      {
        "resource_id": "fuel-uuid",
        "name": "Generator Fuel",
        "current_stock": 0,
        "status": "out_of_stock"
      }
    ],
    "overdue_bills": [],
    "upcoming_bills": []
  },
  "recent_activity": [...]
}
```

---

## Advanced Scenarios

### Scenario 6: Transfer Between Accounts

**Sarah's Goal:** Move $1,000 from bank to petty cash for daily expenses

**Visual Workflow:**
1. Sarah clicks bank account node
2. Clicks "🔄 Transfer"
3. Modal: "Transfer Money"
   - From: Main Business Account
   - To: [dropdown] → Petty Cash
   - Amount: $1,000
4. Clicks "Transfer"
5. **Visual Animation:**
   - Money flows from bank to petty cash
   - Both balances update simultaneously
   - Edge connection shows the transfer
   ```
   [🏦 Main Business] ====💸====> [💵 Petty Cash]
      $48,075                       $1,000
   ```

---

### Scenario 7: Viewing Resource History

**Sarah's Goal:** See all cement transactions and usage

**Visual Workflow:**
1. Sarah clicks "📦 Cement" node
2. Clicks "📊 View History"
3. Side panel slides in showing timeline:
   ```
   📊 Cement History
   
   Current Stock: 70 bags 🟢
   Total Purchased: 100 bags
   Total Used: 30 bags
   Total Spent: $850.00
   
   ──────────────────────────
   Mar 11, 2026
   📤 USAGE: -30 bags
   Used by: Foundation Team
   Project: Johnson House
   Stock after: 70 bags
   
   Mar 10, 2026
   📥 PURCHASE: +100 bags
   Vendor: BuildMart
   Cost: $850.00 ($8.50/bag)
   Stock after: 100 bags
   ──────────────────────────
   ```

**Backend API Call:**
```
GET /api/supplies/cement-uuid/movements

Response:
{
  "resource": {...},
  "current_stock": 70,
  "movements": [
    {
      "id": "...",
      "movement_type": "usage",
      "quantity_change": -30,
      "stock_after_movement": 70,
      "used_by": "Foundation Team",
      "description": "Johnson House Foundation",
      "movement_date": "2026-03-11T14:30:00Z"
    },
    {
      "id": "...",
      "movement_type": "purchase",
      "quantity_change": 100,
      "stock_after_movement": 100,
      "expense_id": "...",
      "movement_date": "2026-03-10T09:15:00Z"
    }
  ]
}
```

---

## Key Visual Interactions

### Node Types & Colors

**Accounts:**
- 🏦 Bank (Blue) - Shows balance, bank name
- 💵 Cash (Green) - Shows balance
- 💰 Funding (Purple) - Shows balance

**Resources:**
- 📦 Supply (Orange) - Shows stock level, status color
- 🏗️ Asset (Gray) - Shows current value, status
- 📅 Subscription (Cyan) - Shows expiry date, status
- 📄 Utility (Yellow) - Shows unpaid amount

**Transactions:**
- 💳 Expense (Red) - Shows amount, vendor
- 📋 Bill (Yellow/Red) - Shows amount, due date, status

### Status Colors
- 🟢 Green: Healthy (good stock, paid, active)
- 🟡 Yellow: Warning (low stock, due soon)
- 🔴 Red: Critical (out of stock, overdue, expired)
- ⚪ Gray: Inactive/Closed

### Edge Types
- Solid line: Active connection
- Dashed line: Historical connection
- Animated: Money flowing
- Thickness: Amount size

---

## API Requirements Summary

### Real-Time Updates Needed
- WebSocket for live balance updates
- Server-sent events for alerts
- Optimistic UI updates

### Batch Operations
- `POST /api/expenses/with-payment` - Expense + Transaction + Stock
- `POST /api/bills/:id/pay` - Bill + Expense + Transaction
- `POST /api/supplies/:id/purchase-with-expense` - Stock + Expense + Transaction

### Dashboard Aggregations
- `GET /api/dashboard` - All summary data
- `GET /api/alerts` - All active alerts
- `GET /api/activity-feed` - Recent transactions

### Visual Data
- Node positions (save canvas layout)
- Edge visibility preferences
- Color theme preferences

---

This is how BookVisually actually works - a visual, interactive experience where users see their business finances as a living diagram, not just data in tables.
