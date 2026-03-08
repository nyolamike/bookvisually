# Expenses Table Schema Guide

## Overview

This schema uses a master-detail pattern to separate expense definitions from expense occurrences:

- **expense_items** (master) - Defines types of expenses (e.g., "Internet Subscription", "Water Bill", "Generator Fuel")
- **expenses** (detail) - Records actual occurrences with date, amount, quantity (e.g., "Paid $50 for Internet on March 8, 2026")

This supports three expense categories with specific tracking:

1. **Subscription** - Track expiry dates for renewals
2. **Postpaid** - Track accumulating usage (increases over billing cycle)
3. **Prepaid** - Track reducing inventory (decreases as consumed)

## Table Structure

### Master Table: `expense_items`

Defines the type of expense:
- `id` - Unique identifier (UUID)
- `name` - Expense name (e.g., "Internet Data Plan")
- `description` - Details about this expense type
- `expense_category` - 'subscription', 'postpaid', or 'prepaid'
- `vendor` - Provider/supplier name
- `status` - 'active' or 'inactive'

Category-specific fields:
- **Subscription:** `renewal_period` (monthly, yearly, etc.)
- **Postpaid:** `unit_of_measure`, `billing_cycle_days`
- **Prepaid:** `default_unit_of_measure`

### Detail Table: `expenses`

Records actual expense occurrences:
- `expense_item_id` - Links to expense_items
- `expense_date` - When this expense occurred
- `unit_cost` - Cost per unit
- `quantity` - How many units
- `unit_of_measure` - Unit type for this occurrence
- `total_amount` - Total cost (unit_cost × quantity)
- `description` - Notes about this specific occurrence

Category-specific fields:
- **Subscription:** `expiry_date`
- **Postpaid:** `billing_cycle_start`, `billing_cycle_end`, `quantity_used`
- **Prepaid:** `initial_quantity`, `remaining_quantity`

### Usage Table: `expense_usage`

Tracks consumption for postpaid and prepaid:
- `expense_id` - Links to specific expense occurrence
- `usage_date` - When consumption happened
- `quantity` - Amount consumed
- `unit_of_measure` - Unit type
- `description` - Usage notes

### Subscription Tracking Table: `resource_subscriptions`

Tracks subscription periods (for subscription resources):
- `resource_id` - Links to the subscription resource
- `expense_id` - Links to the payment that activated this period
- `start_date` - When subscription period begins
- `end_date` - When subscription period expires
- `status` - 'active', 'expired', or 'cancelled'
- `notes` - Additional information

### Bills Table: `bills`

Tracks amounts owed before payment (separate from expenses):
- `resource_id` - Optional link to resource (can be null for one-off bills)
- `bill_type` - 'utility', 'service', 'salary', or 'other'
- `bill_date` - When the bill was issued
- `due_date` - When payment is due
- `amount` - Total amount owed
- `status` - 'unpaid', 'partially_paid', 'paid', 'overdue', 'cancelled'

Bill type-specific fields:
- **Utility:** `meter_reading`, `previous_reading`, `units_consumed`, `unit_of_measure`
- **Service:** `service_description`, `service_period_start`, `service_period_end`
- **Salary:** `employee_name`, `salary_period_start`, `salary_period_end`

### Bill Payments Table: `bill_payments`

Links bills to expense payments (many-to-many):
- `bill_id` - The bill being paid
- `expense_id` - The payment transaction
- `amount_paid` - How much of the bill this payment covers
- `payment_date` - When payment was made

## Usage Examples

### 1. Create Expense Items (One-time setup)

#### Subscription Item
```sql
INSERT INTO expense_items (name, description, expense_category, renewal_period, vendor)
VALUES (
    'Internet Data Plan',
    'Monthly mobile data subscription',
    'subscription',
    'monthly',
    'TelecomCo'
);
```

#### Postpaid Item
```sql
INSERT INTO expense_items (
    name, description, expense_category, 
    unit_of_measure, billing_cycle_days, vendor
)
VALUES (
    'Water Bill',
    'Municipal water supply',
    'postpaid',
    'liters',
    30,
    'Water Utility'
);
```

#### Prepaid Item
```sql
INSERT INTO expense_items (
    name, description, expense_category,
    default_unit_of_measure, vendor
)
VALUES (
    'Generator Fuel',
    'Diesel fuel for backup generator',
    'prepaid',
    'liters',
    'Fuel Station'
);
```

### 2. Record Expense Occurrences

#### Subscription Payment
```sql
-- Record the payment
INSERT INTO expenses (
    resource_id, expense_date, total_amount, description
)
VALUES (
    'resource-uuid',
    '2026-03-08',
    50.00,
    'Monthly renewal payment'
)
RETURNING id;

-- Create the subscription period
INSERT INTO resource_subscriptions (
    resource_id, expense_id, start_date, end_date, status
)
VALUES (
    'resource-uuid',
    'expense-uuid', -- from previous insert
    '2026-03-08',
    '2026-04-08',
    'active'
);
```

#### Postpaid Billing Cycle Start
```sql
INSERT INTO expenses (
    expense_item_id, expense_date, total_amount,
    billing_cycle_start, billing_cycle_end,
    quantity_used, unit_of_measure
)
VALUES (
    'item-uuid',
    '2026-03-01',
    0, -- Will be billed at end of cycle
    '2026-03-01',
    '2026-03-31',
    0,
    'liters'
);
```

#### Prepaid Purchase
```sql
INSERT INTO expenses (
    expense_item_id, expense_date, unit_cost,
    quantity, unit_of_measure, total_amount,
    initial_quantity, remaining_quantity
)
VALUES (
    'item-uuid',
    '2026-03-08',
    2.00,
    100,
    'liters',
    200.00,
    100,
    100
);
```

### 3. Track Usage

#### Record Postpaid Usage (Accumulating)
```sql
-- Log usage event
INSERT INTO expense_usage (expense_id, quantity, unit_of_measure, description)
VALUES ('expense-uuid', 150.5, 'liters', 'Daily water consumption');

-- Update accumulated total
UPDATE expenses 
SET quantity_used = quantity_used + 150.5
WHERE id = 'expense-uuid';
```

#### Record Prepaid Consumption (Reducing)
```sql
-- Log usage event
INSERT INTO expense_usage (expense_id, quantity, unit_of_measure, description)
VALUES ('expense-uuid', 5.0, 'liters', 'Generator run - 2 hours');

-- Update remaining inventory
UPDATE expenses 
SET remaining_quantity = remaining_quantity - 5.0
WHERE id = 'expense-uuid';
```

#### Complete Postpaid Billing Cycle
```sql
-- Record final payment
UPDATE expenses
SET total_amount = 75.50,
    description = 'Water bill payment for March cycle'
WHERE id = 'expense-uuid';
```

### 4. Record Bills (Before Payment)

#### Utility Bill (Water Meter Reading)
```sql
INSERT INTO bills (
    resource_id, bill_type, bill_date, due_date,
    previous_reading, meter_reading, units_consumed,
    unit_of_measure, amount, vendor
)
VALUES (
    'resource-uuid',
    'utility',
    '2026-03-01',
    '2026-03-15',
    1500.0,
    1750.5,
    250.5,
    'liters',
    75.50,
    'Water Utility'
);
```

#### Service Bill (Coaching Session)
```sql
INSERT INTO bills (
    bill_type, bill_date, due_date, amount,
    service_description, service_period_start, service_period_end,
    vendor
)
VALUES (
    'service',
    '2026-03-08',
    '2026-03-22',
    150.00,
    'Leadership coaching session - 2 hours',
    '2026-03-05',
    '2026-03-05',
    'Coach John Doe'
);
```

#### Salary Bill
```sql
INSERT INTO bills (
    bill_type, bill_date, due_date, amount,
    employee_name, salary_period_start, salary_period_end
)
VALUES (
    'salary',
    '2026-03-01',
    '2026-03-05',
    3000.00,
    'Jane Smith',
    '2026-02-01',
    '2026-02-28'
);
```

### 5. Pay Bills

#### Full Payment
```sql
-- Create expense payment
INSERT INTO expenses (expense_date, total_amount, description)
VALUES ('2026-03-10', 75.50, 'Water bill payment')
RETURNING id;

-- Link payment to bill
INSERT INTO bill_payments (bill_id, expense_id, amount_paid, payment_date)
VALUES ('bill-uuid', 'expense-uuid', 75.50, '2026-03-10');

-- Update bill status
UPDATE bills
SET status = 'paid'
WHERE id = 'bill-uuid';
```

#### Partial Payment
```sql
-- Create partial payment
INSERT INTO expenses (expense_date, total_amount, description)
VALUES ('2026-03-10', 50.00, 'Partial water bill payment')
RETURNING id;

-- Link partial payment
INSERT INTO bill_payments (bill_id, expense_id, amount_paid, payment_date)
VALUES ('bill-uuid', 'expense-uuid', 50.00, '2026-03-10');

-- Update bill status
UPDATE bills
SET status = 'partially_paid'
WHERE id = 'bill-uuid';
```

## Helpful Views

### `expiring_subscriptions`
Shows active subscription periods expiring within 30 days, with the payment that activated them

### `low_prepaid_inventory`
Shows prepaid items at 20% or less remaining

### `current_postpaid_usage`
Shows active billing cycles with usage tracking

### `expense_item_history`
Summary of all occurrences per expense item (total spent, frequency, averages)

## Benefits of This Design

1. **No Duplication** - Resource name, vendor, category defined once
2. **Historical Tracking** - See all payments for a specific resource over time
3. **Subscription Periods** - Track active subscription periods separately from payments
4. **Flexible** - Same resource can have different amounts/quantities each time
5. **Reporting** - Easy to analyze spending patterns per resource type
6. **Clean Data** - Update vendor name once, affects all related expenses
7. **Subscription Overlap** - Can handle multiple active periods (e.g., early renewal)

## Phoenix Migration

When setting up Phoenix backend:

```bash
cd backend
mix phx.gen.migration create_expense_tables
```

Then copy the SQL schema into the migration file.
