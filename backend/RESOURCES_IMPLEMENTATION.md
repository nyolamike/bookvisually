# Resources Module Implementation

## Overview

The Resources module manages four types of resources with category-specific properties using a 1:1 relationship pattern.

## Implemented Modules

### 1. Resources Module ✓
Manages four resource types: Supply, Asset, Subscription, and Utility with category-specific properties.

**Tests:** 66 tests ✓

---

### 2. Financial Accounts Module ✓
Tracks all money accounts (cash, bank accounts, funding lines) with balance management.

**Schema:** `FinancialAccount`
- Account types: cash_at_hand, bank_account, funding_line
- Cached balances: current_balance, total_cash_in, total_cash_out
- Status: active, closed, frozen
- Soft delete support

**Key Functions:**
- `create_account/1`
- `increase_balance/2` - For deposits and incoming transfers
- `decrease_balance/2` - For withdrawals and outgoing transfers
- `get_total_balance/0` - Sum across all active accounts
- `list_accounts_by_type/1`, `list_accounts_by_status/1`

**Tests:** 25 tests ✓

---

### 3. Expenses Module ✓
Records actual expense occurrences linked to resources and accounts.

**Schema:** `Expense`
- Links to resources and financial accounts
- Automatic total calculation from unit_cost × quantity
- Date-based filtering and reporting
- Soft delete support

**Key Functions:**
- `create_expense/1` - Auto-calculates total if unit_cost and quantity provided
- `list_expenses_by_resource/1`
- `list_expenses_by_date_range/2`
- `get_total_for_resource/1`
- `get_total_for_date_range/2`

**Tests:** 16 tests ✓

---

## Database Design

### 1. Supply Resources
**Purpose:** Track inventory items (e.g., fuel, materials, supplies)

**Schema:** `SupplyResourceProperties`
- Stock quantity tracking
- Low stock alerts
- Status: in_stock, low_stock, out_of_stock

**Key Functions:**
- `create_supply_properties/1`
- `update_stock_quantity/2` - Auto-updates status based on threshold
- `create_supply_resource/1` - Transaction-safe creation

**Tests:** 15 tests ✓

---

### 2. Asset Resources
**Purpose:** Track fixed assets (e.g., laptops, vehicles, equipment)

**Schema:** `AssetResourceProperties`
- Purchase info (date, cost)
- Depreciation tracking (method, rate, current value)
- Warranty and guarantee management
- Status: okay, in_use, offsite, damaged, destroyed, disposed

**Key Functions:**
- `create_asset_properties/1`
- `update_asset_value/2`
- `update_warranty_status/2`
- `update_guarantee_status/2`
- `create_asset_resource/1` - Transaction-safe creation

**Tests:** 15 tests ✓

---

### 3. Subscription Resources
**Purpose:** Track recurring subscriptions (e.g., internet plans, software licenses)

**Schema:** `SubscriptionResourceProperties`
- Vendor and package info
- Renewal period tracking
- Expiry alerts
- Current subscription period (start/end dates)
- Status: active, expired, cancelled

**Key Functions:**
- `create_subscription_properties/1`
- `update_subscription_period/3` - Updates dates and sets to active
- `expire_subscription/1`
- `cancel_subscription/1`
- `create_subscription_resource/1` - Transaction-safe creation

**Tests:** 10 tests ✓

---

### 4. Utility Resources
**Purpose:** Track utility bills and services (e.g., water, electricity, rent)

**Schema:** `UtilityResourceProperties`
- Bill type: utility, service, salary, rent, other
- Billing cycle tracking
- Due date alerts
- Current bill status: paid, unpaid, partially_paid, overdue
- Consumption tracking

**Key Functions:**
- `create_utility_properties/1`
- `update_bill_status/2`
- `update_bill_dates/3`
- `update_consumption/2`
- `create_utility_resource/1` - Transaction-safe creation

**Tests:** 11 tests ✓

---

## Core Resource Functions

All resource types share these base functions:

- `list_resources/0` - Returns active resources only
- `list_resources_by_category/1` - Filter by category
- `get_resource!/1` - Get single resource (active only)
- `get_resource_with_deleted!/1` - Include soft-deleted
- `create_resource/1`
- `update_resource/2`
- `soft_delete_resource/1`
- `restore_resource/1`

**Tests:** 15 tests ✓

---

## Database Design

### Soft Deletes
All resources use soft delete pattern:
- `is_deleted` (boolean) - Fast filtering
- `deleted_at` (timestamp) - Audit trail

### 1:1 Relationships
Each resource category has its own properties table with `resource_id` as primary key and foreign key.

### Cached Values
Properties tables cache current state for performance:
- Supply: current stock quantity and status
- Asset: current value
- Subscription: current period dates and status
- Utility: current bill status and consumption

### Constraints
All tables use database-level constraints for data integrity:
- Status enums
- Non-negative values
- Required fields

---

## Migrations

1. `20260308191010_create_resources.exs` - Base resources table
2. `20260308194615_create_supply_resource_properties.exs`
3. `20260308201840_create_asset_resource_properties.exs`
4. `20260308202209_create_subscription_resource_properties.exs`
5. `20260308202517_create_utility_resource_properties.exs`

---

## Test Coverage

**Total:** 66 tests, 0 failures ✓

- Resources (base): 15 tests
- Supply Properties: 15 tests
- Asset Properties: 15 tests
- Subscription Properties: 10 tests
- Utility Properties: 11 tests

All tests include:
- Valid data creation
- Invalid data validation
- Status/enum validation
- CRUD operations
- Transaction rollback verification
- Combined resource+properties creation

---

## Next Steps

Potential future enhancements:
1. Implement expense tracking linked to resources
2. Add resource status change audit trail
3. Implement unit conversion system
4. Add financial accounts integration
5. Create resource subscription periods tracking
6. Implement supply stock movements
7. Add utility bills management
