# BookVisually - Use Cases & API Requirements

## Overview

This document outlines the user workflows and API endpoints needed for the BookVisually application.

---

## Core User Workflows

### 1. Resource Management

#### Use Case 1.1: Create a Supply Resource
**Actor:** Business Owner  
**Goal:** Add a new supply item to track (e.g., Generator Fuel)

**Steps:**
1. User enters resource name, category, and unit of measure
2. User sets stock alert threshold
3. System creates resource and supply properties
4. System displays confirmation

**API Endpoint:** `POST /api/resources`
```json
{
  "name": "Generator Fuel",
  "resource_category": "supply",
  "default_unit_of_measure": "liters",
  "supply_properties": {
    "out_of_stock_alert_quantity": 10,
    "issues_out_of_stock_alerts": true
  }
}
```

#### Use Case 1.2: Create an Asset Resource
**Actor:** Business Owner  
**Goal:** Register a new asset (e.g., Office Laptop)

**Steps:**
1. User enters asset details (name, purchase date, cost)
2. User optionally adds warranty/guarantee info
3. System creates resource and asset properties
4. System displays confirmation

**API Endpoint:** `POST /api/resources`

#### Use Case 1.3: View All Resources
**Actor:** Business Owner  
**Goal:** See all tracked resources

**API Endpoint:** `GET /api/resources`
**Query Params:** `?category=supply` (optional filter)

#### Use Case 1.4: View Resource Details
**Actor:** Business Owner  
**Goal:** See detailed information about a specific resource

**API Endpoint:** `GET /api/resources/:id`

---

### 2. Financial Account Management

#### Use Case 2.1: Create a Bank Account
**Actor:** Business Owner  
**Goal:** Add a bank account to track

**Steps:**
1. User enters account name, bank name, account number
2. System creates account with zero balance
3. System displays confirmation

**API Endpoint:** `POST /api/accounts`
```json
{
  "name": "Main Business Account",
  "account_type": "bank_account",
  "bank_name": "First National Bank",
  "account_number": "1234567890"
}
```

#### Use Case 2.2: View All Accounts
**Actor:** Business Owner  
**Goal:** See all financial accounts and their balances

**API Endpoint:** `GET /api/accounts`
**Response includes:** current_balance, total_cash_in, total_cash_out

#### Use Case 2.3: View Account Details with Transaction History
**Actor:** Business Owner  
**Goal:** See account details and recent transactions

**API Endpoint:** `GET /api/accounts/:id`
**API Endpoint:** `GET /api/accounts/:id/transactions`

---

### 3. Money Flow (Transactions)

#### Use Case 3.1: Record a Deposit
**Actor:** Business Owner  
**Goal:** Record money coming into an account (investment, income)

**Steps:**
1. User selects destination account
2. User enters amount and description
3. System creates deposit transaction
4. System updates account balance
5. System displays updated balance

**API Endpoint:** `POST /api/transactions/deposit`
```json
{
  "to_account_id": "uuid",
  "amount": 5000.00,
  "description": "Initial investment"
}
```

#### Use Case 3.2: Transfer Money Between Accounts
**Actor:** Business Owner  
**Goal:** Move money from one account to another

**Steps:**
1. User selects source and destination accounts
2. User enters amount
3. System validates sufficient balance
4. System creates transfer transaction
5. System updates both account balances

**API Endpoint:** `POST /api/transactions/transfer`
```json
{
  "from_account_id": "uuid",
  "to_account_id": "uuid",
  "amount": 1000.00,
  "description": "Transfer to petty cash"
}
```

#### Use Case 3.3: Record a Withdrawal
**Actor:** Business Owner  
**Goal:** Record money leaving an account

**API Endpoint:** `POST /api/transactions/withdrawal`

#### Use Case 3.4: View Transaction History
**Actor:** Business Owner  
**Goal:** See all money movements

**API Endpoint:** `GET /api/transactions`
**Query Params:** `?account_id=uuid`, `?start_date=2026-01-01`, `?end_date=2026-12-31`

---

### 4. Expense Tracking

#### Use Case 4.1: Record a Simple Expense
**Actor:** Business Owner  
**Goal:** Record an expense without detailed tracking

**Steps:**
1. User selects resource (what was purchased)
2. User enters date and total amount
3. User optionally selects payment account
4. System creates expense record

**API Endpoint:** `POST /api/expenses`
```json
{
  "resource_id": "uuid",
  "expense_date": "2026-03-08",
  "total_amount": 250.00,
  "paid_from_account_id": "uuid",
  "description": "Fuel purchase"
}
```

#### Use Case 4.2: Record an Expense with Quantity
**Actor:** Business Owner  
**Goal:** Record expense with unit cost and quantity

**API Endpoint:** `POST /api/expenses`
```json
{
  "resource_id": "uuid",
  "expense_date": "2026-03-08",
  "unit_cost": 2.50,
  "quantity": 100,
  "unit_of_measure": "liters",
  "paid_from_account_id": "uuid"
}
```
**Note:** System auto-calculates total_amount

#### Use Case 4.3: Record Expense Payment (with Account Transaction)
**Actor:** Business Owner  
**Goal:** Record expense and deduct from account in one action

**Steps:**
1. User enters expense details
2. User selects payment account
3. System creates expense
4. System creates account transaction
5. System updates account balance

**API Endpoint:** `POST /api/expenses/with-payment`

#### Use Case 4.4: View Expenses by Resource
**Actor:** Business Owner  
**Goal:** See all expenses for a specific resource

**API Endpoint:** `GET /api/resources/:id/expenses`

#### Use Case 4.5: View Expenses by Date Range
**Actor:** Business Owner  
**Goal:** See expenses within a time period

**API Endpoint:** `GET /api/expenses?start_date=2026-01-01&end_date=2026-12-31`

---

### 5. Inventory Management (Supply Resources)

#### Use Case 5.1: Record a Purchase (Stock In)
**Actor:** Business Owner  
**Goal:** Record buying supplies and increase stock

**Steps:**
1. User selects supply resource
2. User enters quantity purchased
3. User optionally links to expense
4. System creates stock movement
5. System updates stock level
6. System updates status (in_stock, low_stock, out_of_stock)

**API Endpoint:** `POST /api/supplies/:resource_id/movements/purchase`
```json
{
  "quantity_change": 100,
  "unit_of_measure": "liters",
  "expense_id": "uuid",
  "description": "Fuel purchase from Station A"
}
```

#### Use Case 5.2: Record Usage (Stock Out)
**Actor:** Business Owner  
**Goal:** Record using supplies and decrease stock

**Steps:**
1. User selects supply resource
2. User enters quantity used
3. User enters who used it and why
4. System creates stock movement
5. System updates stock level
6. System checks if stock is low

**API Endpoint:** `POST /api/supplies/:resource_id/movements/usage`
```json
{
  "quantity_change": 20,
  "used_by": "John the Carpenter",
  "description": "Generator run - 4 hours"
}
```

#### Use Case 5.3: View Stock Movement History
**Actor:** Business Owner  
**Goal:** See all stock changes for a supply

**API Endpoint:** `GET /api/supplies/:resource_id/movements`

#### Use Case 5.4: View Current Stock Levels
**Actor:** Business Owner  
**Goal:** See current stock for all supplies

**API Endpoint:** `GET /api/supplies/stock-levels`
**Response:** List of supplies with current_stock_quantity and status

#### Use Case 5.5: View Low Stock Alerts
**Actor:** Business Owner  
**Goal:** See which supplies need restocking

**API Endpoint:** `GET /api/supplies/low-stock`

---

### 6. Bill Management

#### Use Case 6.1: Create a Utility Bill
**Actor:** Business Owner  
**Goal:** Record a bill received (before payment)

**Steps:**
1. User enters bill details (date, due date, amount)
2. User optionally enters meter readings
3. System calculates consumption
4. System creates bill with "unpaid" status

**API Endpoint:** `POST /api/bills`
```json
{
  "resource_id": "uuid",
  "bill_date": "2026-03-01",
  "due_date": "2026-03-15",
  "bill_reading": 1750.5,
  "previous_reading": 1500.0,
  "unit_of_measure": "liters",
  "unit_cost": 0.30,
  "total_amount": 75.15,
  "vendor": "Water Utility Co"
}
```

#### Use Case 6.2: View Unpaid Bills
**Actor:** Business Owner  
**Goal:** See all bills that need to be paid

**API Endpoint:** `GET /api/bills/unpaid`
**Sorted by:** due_date ascending

#### Use Case 6.3: View Overdue Bills
**Actor:** Business Owner  
**Goal:** See bills past their due date

**API Endpoint:** `GET /api/bills/overdue`

#### Use Case 6.4: Mark Bill as Paid
**Actor:** Business Owner  
**Goal:** Update bill status after payment

**API Endpoint:** `PATCH /api/bills/:id/mark-paid`

#### Use Case 6.5: Pay Bill (Create Expense + Update Bill)
**Actor:** Business Owner  
**Goal:** Record payment and update bill status in one action

**Steps:**
1. User selects bill to pay
2. User selects payment account
3. System creates expense
4. System creates account transaction
5. System updates bill status to "paid"
6. System updates account balance

**API Endpoint:** `POST /api/bills/:id/pay`
```json
{
  "paid_from_account_id": "uuid",
  "payment_date": "2026-03-10"
}
```

---

## Dashboard & Reporting Use Cases

### Use Case 7.1: View Financial Dashboard
**Actor:** Business Owner  
**Goal:** See overall financial status

**API Endpoint:** `GET /api/dashboard`
**Response includes:**
- Total balance across all accounts
- Total unpaid bills
- Low stock alerts count
- Recent transactions
- Upcoming bill due dates

### Use Case 7.2: View Resource Summary
**Actor:** Business Owner  
**Goal:** See summary of all resources

**API Endpoint:** `GET /api/resources/summary`
**Response includes:**
- Total resources by category
- Total expenses per resource
- Supply stock status counts

### Use Case 7.3: Generate Expense Report
**Actor:** Business Owner  
**Goal:** See expenses for a time period

**API Endpoint:** `GET /api/reports/expenses`
**Query Params:** `?start_date=2026-01-01&end_date=2026-12-31&resource_id=uuid`

---

## API Endpoints Summary

### Resources
- `GET /api/resources` - List all resources
- `GET /api/resources/:id` - Get resource details
- `POST /api/resources` - Create resource
- `PATCH /api/resources/:id` - Update resource
- `DELETE /api/resources/:id` - Soft delete resource
- `GET /api/resources/:id/expenses` - Get expenses for resource

### Financial Accounts
- `GET /api/accounts` - List all accounts
- `GET /api/accounts/:id` - Get account details
- `POST /api/accounts` - Create account
- `PATCH /api/accounts/:id` - Update account
- `DELETE /api/accounts/:id` - Soft delete account
- `GET /api/accounts/:id/transactions` - Get account transactions

### Transactions
- `GET /api/transactions` - List all transactions
- `POST /api/transactions/deposit` - Record deposit
- `POST /api/transactions/withdrawal` - Record withdrawal
- `POST /api/transactions/transfer` - Record transfer
- `POST /api/transactions/income` - Record income

### Expenses
- `GET /api/expenses` - List all expenses
- `GET /api/expenses/:id` - Get expense details
- `POST /api/expenses` - Create expense
- `POST /api/expenses/with-payment` - Create expense + transaction
- `PATCH /api/expenses/:id` - Update expense
- `DELETE /api/expenses/:id` - Soft delete expense

### Supply Stock Movements
- `GET /api/supplies/:resource_id/movements` - List movements
- `POST /api/supplies/:resource_id/movements/purchase` - Record purchase
- `POST /api/supplies/:resource_id/movements/usage` - Record usage
- `POST /api/supplies/:resource_id/movements/adjustment` - Record adjustment
- `GET /api/supplies/stock-levels` - Get all stock levels
- `GET /api/supplies/low-stock` - Get low stock alerts

### Bills
- `GET /api/bills` - List all bills
- `GET /api/bills/unpaid` - List unpaid bills
- `GET /api/bills/overdue` - List overdue bills
- `GET /api/bills/:id` - Get bill details
- `POST /api/bills` - Create bill
- `PATCH /api/bills/:id` - Update bill
- `DELETE /api/bills/:id` - Soft delete bill
- `PATCH /api/bills/:id/mark-paid` - Mark as paid
- `POST /api/bills/:id/pay` - Pay bill (expense + transaction)

### Dashboard & Reports
- `GET /api/dashboard` - Get dashboard summary
- `GET /api/resources/summary` - Get resource summary
- `GET /api/reports/expenses` - Generate expense report

---

## Next Steps

1. **Implement Controllers** - Create Phoenix controllers for each endpoint
2. **Implement JSON Views** - Create JSON serializers for responses
3. **Add Routes** - Configure router with all endpoints
4. **Add Validation** - Request parameter validation
5. **Error Handling** - Consistent error responses
6. **Documentation** - OpenAPI/Swagger documentation
7. **Testing** - Controller tests for each endpoint

---

## Notes

- All endpoints return JSON
- All dates in ISO 8601 format
- All amounts as decimals with 2 decimal places
- Soft deletes: deleted resources return 404
- Pagination needed for list endpoints (future enhancement)
- Authentication/Authorization not yet implemented
