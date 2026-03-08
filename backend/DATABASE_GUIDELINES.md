# BookVisually Database Guidelines

## Soft Deletes

All main tables use soft deletes with two columns:
- `is_deleted` (BOOLEAN) - Fast filtering
- `deleted_at` (TIMESTAMP) - Audit trail

### Tables with Soft Deletes
- `resources`
- `expenses`
- `financial_accounts`
- `utility_bills`

### Critical Rule: Always Filter Deleted Records

**❌ WRONG - Will include deleted records:**
```sql
SELECT * FROM resources;
SELECT * FROM expenses WHERE resource_id = 'abc-123';
SELECT * FROM financial_accounts WHERE account_type = 'bank_account';
```

**✅ CORRECT - Filters out deleted records:**
```sql
SELECT * FROM resources WHERE is_deleted = false;
SELECT * FROM expenses WHERE resource_id = 'abc-123' AND is_deleted = false;
SELECT * FROM financial_accounts WHERE account_type = 'bank_account' AND is_deleted = false;
```

### Phoenix/Ecto Implementation

In your Ecto schemas, add a default scope:

```elixir
defmodule BookVisually.Resources.Resource do
  use Ecto.Schema
  import Ecto.Query
  
  schema "resources" do
    field :name, :string
    field :is_deleted, :boolean, default: false
    field :deleted_at, :utc_datetime
    # ... other fields
  end
  
  # Default scope - filters deleted records
  def active(query \\ __MODULE__) do
    from r in query, where: r.is_deleted == false
  end
  
  # Include deleted records when needed
  def with_deleted(query \\ __MODULE__) do
    query
  end
end

# Usage:
Resource.active() |> Repo.all()  # Only active
Resource.with_deleted() |> Repo.all()  # Include deleted
```

### Soft Delete Operation

```sql
-- Soft delete
UPDATE resources 
SET is_deleted = true, 
    deleted_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'resource-id';
```

```elixir
# In Phoenix
def soft_delete(resource) do
  resource
  |> Ecto.Changeset.change(%{
    is_deleted: true,
    deleted_at: DateTime.utc_now()
  })
  |> Repo.update()
end
```

### Restore Operation

```sql
-- Restore
UPDATE resources 
SET is_deleted = false, 
    deleted_at = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'resource-id';
```

### Hard Delete (Permanent)

Only use when absolutely necessary (GDPR, data retention policies):

```sql
DELETE FROM resources WHERE id = 'resource-id' AND is_deleted = true;
```

## Unit Conversions

Resources have custom unit conversions stored in `resource_unit_conversions`.

### Always Convert to Default Unit

When recording expenses or stock movements with different units:

```elixir
def record_expense(resource, quantity, unit) do
  # 1. Get resource default unit
  default_unit = resource.default_unit_of_measure
  
  # 2. Convert if needed
  converted_quantity = if unit == default_unit do
    quantity
  else
    convert_unit(resource.id, quantity, unit, default_unit)
  end
  
  # 3. Store in default unit
  create_expense(%{
    quantity: converted_quantity,
    unit_of_measure: default_unit
  })
end

def convert_unit(resource_id, quantity, from_unit, to_unit) do
  conversion = Repo.get_by(ResourceUnitConversion,
    resource_id: resource_id,
    from_unit: from_unit,
    to_unit: to_unit
  )
  
  if conversion do
    Decimal.mult(quantity, conversion.conversion_factor)
  else
    raise "No conversion found from #{from_unit} to #{to_unit}"
  end
end
```

## Financial Transactions

### Money Flow Rules

1. **Deposits** - Money coming in
   - `from_account_id` = NULL
   - `to_account_id` = required
   - Example: Investment, income received

2. **Withdrawals** - Money going out
   - `from_account_id` = required
   - `to_account_id` = NULL
   - Example: Cash withdrawal

3. **Transfers** - Between accounts
   - `from_account_id` = required
   - `to_account_id` = required
   - Example: Bank to cash at hand

4. **Expenses** - Paying for something
   - `from_account_id` = required
   - `expense_id` = required
   - Example: Buying supplies

5. **Income** - Revenue received
   - `to_account_id` = required
   - Example: Customer payment

### Always Update Account Balances

When creating account transactions, update the account balances:

```elixir
def create_transaction(attrs) do
  Repo.transaction(fn ->
    # 1. Create transaction
    transaction = create_account_transaction(attrs)
    
    # 2. Update account balances
    case attrs.transaction_type do
      "deposit" ->
        update_balance(attrs.to_account_id, :increase, attrs.amount)
        
      "withdrawal" ->
        update_balance(attrs.from_account_id, :decrease, attrs.amount)
        
      "transfer" ->
        update_balance(attrs.from_account_id, :decrease, attrs.amount)
        update_balance(attrs.to_account_id, :increase, attrs.amount)
        
      "expense" ->
        update_balance(attrs.from_account_id, :decrease, attrs.amount)
        
      "income" ->
        update_balance(attrs.to_account_id, :increase, attrs.amount)
    end
    
    transaction
  end)
end

defp update_balance(account_id, :increase, amount) do
  from(a in FinancialAccount, where: a.id == ^account_id)
  |> Repo.update_all(
    inc: [current_balance: amount, total_cash_in: amount],
    set: [updated_at: DateTime.utc_now()]
  )
end

defp update_balance(account_id, :decrease, amount) do
  from(a in FinancialAccount, where: a.id == ^account_id)
  |> Repo.update_all(
    inc: [current_balance: -amount, total_cash_out: amount],
    set: [updated_at: DateTime.utc_now()]
  )
end
```

## Supply Stock Management

### Always Update Stock Levels

When recording supply movements:

```elixir
def record_stock_movement(resource_id, movement_type, quantity_change) do
  Repo.transaction(fn ->
    # 1. Get current stock
    properties = Repo.get!(SupplyResourceProperties, resource_id)
    new_stock = Decimal.add(properties.current_stock_quantity, quantity_change)
    
    # 2. Create movement record
    movement = create_supply_stock_movement(%{
      resource_id: resource_id,
      movement_type: movement_type,
      quantity_change: quantity_change,
      stock_after_movement: new_stock
    })
    
    # 3. Update cached stock
    properties
    |> Ecto.Changeset.change(%{
      current_stock_quantity: new_stock,
      status: determine_stock_status(new_stock, properties.out_of_stock_alert_quantity)
    })
    |> Repo.update!()
    
    movement
  end)
end

defp determine_stock_status(quantity, alert_threshold) do
  cond do
    Decimal.equal?(quantity, 0) -> "out_of_stock"
    Decimal.lt?(quantity, alert_threshold) -> "low_stock"
    true -> "in_stock"
  end
end
```

## Status Change Tracking

Always log status changes to `resource_status_changes`:

```elixir
def update_resource_status(resource, status_type, new_status, activity, reason \\ nil) do
  Repo.transaction(fn ->
    # 1. Get current status
    old_status = get_current_status(resource, status_type)
    
    # 2. Update status
    update_status_field(resource, status_type, new_status)
    
    # 3. Log change
    create_status_change(%{
      resource_id: resource.id,
      status_type: status_type,
      previous_status: old_status,
      new_status: new_status,
      activity: activity,
      change_reason: reason,
      changed_by_user_id: get_current_user_id()
    })
  end)
end
```

## Query Performance Tips

### Use Indexes Effectively

```sql
-- Good - Uses index
SELECT * FROM expenses 
WHERE resource_id = 'abc-123' 
  AND is_deleted = false
  AND expense_date >= '2026-01-01';

-- Bad - Full table scan
SELECT * FROM expenses 
WHERE EXTRACT(YEAR FROM expense_date) = 2026;
```

### Use Partial Indexes

Many indexes have `WHERE is_deleted = false` for better performance:

```sql
CREATE INDEX idx_expenses_resource_date 
ON expenses(resource_id, expense_date) 
WHERE is_deleted = false;
```

### Avoid N+1 Queries

```elixir
# Bad - N+1 query
resources = Repo.all(Resource.active())
Enum.map(resources, fn r -> 
  Repo.get(SubscriptionResourceProperties, r.id)
end)

# Good - Preload
resources = 
  Resource.active()
  |> Repo.all()
  |> Repo.preload(:subscription_properties)
```

## Data Integrity

### Always Use Transactions

For operations that modify multiple tables:

```elixir
Repo.transaction(fn ->
  # Multiple operations
  expense = create_expense(attrs)
  create_account_transaction(expense)
  update_stock_movement(expense)
end)
```

### Validate Before Insert

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :amount, ...])
  |> validate_required([:name, :amount])
  |> validate_number(:amount, greater_than_or_equal_to: 0)
  |> validate_inclusion(:status, ["active", "inactive"])
end
```

## Common Queries

### Active Resources by Category
```sql
SELECT * FROM resources 
WHERE resource_category = 'supply' 
  AND is_deleted = false
ORDER BY name;
```

### Account Balance
```sql
SELECT name, current_balance, total_cash_in, total_cash_out
FROM financial_accounts
WHERE is_deleted = false
  AND status = 'active';
```

### Unpaid Bills
```sql
SELECT * FROM utility_bills
WHERE status IN ('unpaid', 'partially_paid')
  AND is_deleted = false
ORDER BY due_date ASC;
```

### Low Stock Supplies
```sql
SELECT r.name, srp.current_stock_quantity, srp.out_of_stock_alert_quantity
FROM resources r
JOIN supply_resource_properties srp ON r.id = srp.resource_id
WHERE r.resource_category = 'supply'
  AND r.is_deleted = false
  AND srp.status IN ('low_stock', 'out_of_stock');
```

### Expense History
```sql
SELECT e.expense_date, e.total_amount, r.name, fa.name as paid_from
FROM expenses e
JOIN resources r ON e.resource_id = r.id
LEFT JOIN financial_accounts fa ON e.paid_from_account_id = fa.id
WHERE e.is_deleted = false
  AND e.expense_date >= '2026-01-01'
ORDER BY e.expense_date DESC;
```
