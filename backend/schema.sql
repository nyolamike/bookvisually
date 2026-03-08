-- BookVisually Database Schema
-- Core tables with category-specific property tables (1:1 relationships)

-- Resources table (base - all resources)
CREATE TABLE resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    resource_category VARCHAR(50) NOT NULL CHECK (resource_category IN ('subscription', 'utility', 'supply', 'asset')),
    default_unit_of_measure VARCHAR(50),
    default_unit_cost DECIMAL(15, 2),
    
    -- Inspection tracking (applies to all categories)
    needs_periodic_inspection BOOLEAN DEFAULT false,
    inspection_interval_days INTEGER,
    last_inspection_date DATE,
    next_inspection_date DATE,
    days_to_inspection_alert INTEGER,
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraint: If inspection is needed, interval must be specified
    -- This ensures data integrity - can't enable inspections without defining frequency
    -- Valid in PostgreSQL; Ecto will validate this at database level
    CHECK (
        (needs_periodic_inspection = false) OR 
        (needs_periodic_inspection = true AND inspection_interval_days IS NOT NULL)
    )
);

-- Subscription resource properties (1:1 with resources)
CREATE TABLE subscription_resource_properties (
    resource_id UUID PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
    renewal_period VARCHAR(20), -- 'monthly', 'yearly', 'quarterly', etc.

    vendor VARCHAR(255) NOT NULL,
    package VARCHAR(255) NOT NULL,
    
    -- Alert settings
    issues_expiry_alerts BOOLEAN DEFAULT false,
    days_left_to_alert INTEGER,
    
    -- Current subscription (cached for performance)
    current_subscription_start_date DATE,
    current_subscription_end_date DATE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Utility resource properties (1:1 with resources)
CREATE TABLE utility_resource_properties (
    resource_id UUID PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
    bill_type VARCHAR(50) NOT NULL CHECK (bill_type IN ('utility', 'service', 'salary', 'rent', 'other')),
    billing_cycle_days INTEGER,
    
    -- Alert settings
    issues_bill_due_alerts BOOLEAN DEFAULT false,
    days_to_due_date_alert INTEGER,
    
    -- Current bill status (cached for performance)
    current_bill_status VARCHAR(20) DEFAULT 'paid' CHECK (current_bill_status IN ('paid', 'unpaid', 'partially_paid', 'overdue')),
    last_bill_date DATE,
    next_bill_due_date DATE,
    current_bill_quantity_consumed DECIMAL(15, 4),
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Supply resource properties (1:1 with resources)
CREATE TABLE supply_resource_properties (
    resource_id UUID PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
    
    -- Alert settings
    issues_out_of_stock_alerts BOOLEAN DEFAULT false,
    out_of_stock_alert_quantity DECIMAL(15, 4),
    
    -- Current inventory (cached for performance)
    current_stock_quantity DECIMAL(15, 4) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'in_stock' CHECK (status IN ('in_stock', 'low_stock', 'out_of_stock')),
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Asset resource properties (1:1 with resources)
CREATE TABLE asset_resource_properties (
    resource_id UUID PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
    
    -- Purchase info
    purchase_date DATE NOT NULL,
    purchase_cost DECIMAL(15, 2) NOT NULL,
    
    -- Depreciation
    depreciation_method VARCHAR(50) CHECK (depreciation_method IN ('straight_line', 'declining_balance', 'none')),
    depreciation_rate DECIMAL(5, 2), -- Percentage
    current_value DECIMAL(15, 2),
    
    -- Warranty
    has_warranty BOOLEAN DEFAULT false,
    warranty_expiry_date DATE,
    warranty_status VARCHAR(20) DEFAULT 'na' CHECK (warranty_status IN ('na', 'active', 'used', 'expired')),
    
    -- Guarantee
    has_guarantee BOOLEAN DEFAULT false,
    guarantee_expiry_date DATE,
    guarantee_status VARCHAR(20) DEFAULT 'na' CHECK (guarantee_status IN ('na', 'active', 'used', 'expired')),
    
    -- Asset status
    status VARCHAR(20) DEFAULT 'okay' CHECK (status IN ('okay', 'in_use', 'offsite', 'damaged', 'destroyed', 'disposed')),
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Expenses table (records actual expense occurrences/payments)
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    paid_from_account_id UUID REFERENCES financial_accounts(id) ON DELETE SET NULL, -- Which account paid for this
    expense_date DATE NOT NULL,
    unit_cost DECIMAL(15, 2),
    quantity DECIMAL(15, 4),
    unit_of_measure VARCHAR(50),
    total_amount DECIMAL(15, 2) NOT NULL,
    description TEXT,
    
    -- Metadata
    payment_method VARCHAR(50), 
    reference_number VARCHAR(100),
    notes TEXT,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (total_amount >= 0)
);

-- Resource subscriptions table (tracks subscription periods)
CREATE TABLE resource_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    expense_id UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    vendor VARCHAR(255),
    vendor_package VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (end_date > start_date),
    UNIQUE(resource_id, start_date, end_date, vendor)
);

-- Supply stock movements table (tracks inventory changes)
CREATE TABLE supply_stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    expense_id UUID REFERENCES expenses(id) ON DELETE SET NULL, -- Link to purchase if applicable
    movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('purchase', 'usage', 'adjustment', 'disposal', 'return')),
    movement_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Quantity change (positive = increase, negative = decrease)
    quantity_change DECIMAL(15, 4) NOT NULL,
    unit_of_measure VARCHAR(50),
    
    -- Stock level after this movement (cached for performance)
    stock_after_movement DECIMAL(15, 4) NOT NULL,
    
    -- Who used it (for usage tracking)
    used_by VARCHAR(255), -- e.g., "John the Carpenter", "Project ABC"
    
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (quantity_change != 0),
    CHECK (stock_after_movement >= 0)
);

-- Resource unit conversions table (resource-specific unit conversion rules)
CREATE TABLE resource_unit_conversions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    from_unit VARCHAR(50) NOT NULL,
    to_unit VARCHAR(50) NOT NULL,
    conversion_factor DECIMAL(15, 6) NOT NULL, -- Multiply by this to convert from_unit to to_unit
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure unique conversion pairs per resource
    UNIQUE(resource_id, from_unit, to_unit),
    
    -- Conversion factor must be positive
    CHECK (conversion_factor > 0),
    
    -- Can't convert unit to itself
    CHECK (from_unit != to_unit)
);

-- Financial accounts table (tracks all money accounts)
CREATE TABLE financial_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    account_type VARCHAR(50) NOT NULL CHECK (account_type IN (
        'cash_at_hand',      -- Physical cash at reception/office
        'bank_account',      -- Bank accounts
        'funding_line',      -- Investment/funding accounts
    )),
    
    -- Current balance (cached for performance)
    current_balance DECIMAL(15, 2) DEFAULT 0,
    
    -- Totals (cached for performance)
    total_cash_in DECIMAL(15, 2) DEFAULT 0,
    total_cash_out DECIMAL(15, 2) DEFAULT 0,
    
    -- Bank account specific fields
    bank_name VARCHAR(255),
    account_number VARCHAR(100),
    
    -- Status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'frozen')),
    
    notes TEXT,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (current_balance >= 0)
);

-- Account transactions table (tracks all money movements)
CREATE TABLE account_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
        'deposit',           -- Money coming in (investment, revenue, etc.)
        'withdrawal',        -- Money going out (expenses, transfers out)
        'transfer',          -- Money moving between accounts
        'expense',           -- Payment for an expense
        'income',            -- Revenue/income received
        'adjustment'         -- Balance correction
    )),
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Source and destination accounts
    from_account_id UUID REFERENCES financial_accounts(id) ON DELETE SET NULL,
    to_account_id UUID REFERENCES financial_accounts(id) ON DELETE SET NULL,
    
    -- Amount
    amount DECIMAL(15, 2) NOT NULL,
    
    -- Links to related records
    expense_id UUID REFERENCES expenses(id) ON DELETE SET NULL,
    
    -- Transaction details
    reference_number VARCHAR(100),
    description TEXT,
    
    -- Who initiated this transaction
    initiated_by_user_id INTEGER DEFAULT 1, -- 1 = system
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (amount > 0),
    
    -- Ensure proper account usage based on transaction type
    CHECK (
        (transaction_type = 'deposit' AND from_account_id IS NULL AND to_account_id IS NOT NULL) OR
        (transaction_type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL) OR
        (transaction_type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL) OR
        (transaction_type = 'expense' AND from_account_id IS NOT NULL AND expense_id IS NOT NULL) OR
        (transaction_type = 'income' AND to_account_id IS NOT NULL) OR
        (transaction_type = 'adjustment')
    )
);

-- Bills table (tracks amounts owed before payment)
CREATE TABLE utility_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID REFERENCES resources(id) ON DELETE SET NULL,
    
    bill_date DATE NOT NULL,
    due_date DATE,
    
    -- Meter/reading fields
    bill_reading DECIMAL(15, 4),
    previous_reading DECIMAL(15, 4),
    quantity_consumed DECIMAL(15, 4),
    unit_of_measure VARCHAR(50),
    
    unit_cost DECIMAL(15, 2),
    total_amount DECIMAL(15, 2) NOT NULL,
    
    vendor VARCHAR(255),
    reference_number VARCHAR(100),
    status VARCHAR(20) DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partially_paid', 'paid', 'overdue', 'cancelled')),
    notes TEXT,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (total_amount >= 0),
    CHECK (due_date IS NULL OR due_date >= bill_date)
);

-- Bill payments table (links bills to expense payments)
CREATE TABLE utility_bill_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL REFERENCES utility_bills(id) ON DELETE CASCADE,
    expense_id UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    amount_paid DECIMAL(15, 2) NOT NULL,
    payment_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (amount_paid > 0)
);

-- Resource status changes table (audit trail)
CREATE TABLE resource_status_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    status_type VARCHAR(50) NOT NULL CHECK (status_type IN ('subscription', 'utility', 'asset', 'supply')),
    previous_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    change_reason TEXT,
    -- Activity types that trigger status changes
    activity VARCHAR(50) NOT NULL CHECK (activity IN (
        'purchase',        -- Bought new supply/asset
        'stockin',         -- Restocked supply
        'stockout',        -- Supply depleted/removed
        'usage',           -- Used/consumed
        'payment',         -- Bill/subscription paid
        'expiry',          -- Subscription/warranty expired
        'renewal',         -- Subscription renewed
        'repair',          -- Asset repaired
        'damage',          -- Asset damaged
        'disposal',        -- Asset disposed
        'inspection',      -- Inspection completed
        'manual_update'    -- Manual status change by user
    )),
    changed_by_user_id INTEGER DEFAULT 1, -- 1 = system
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Indexes for performance
-- Resources table
CREATE INDEX idx_resources_category ON resources(resource_category);
CREATE INDEX idx_resources_is_deleted ON resources(is_deleted);
CREATE INDEX idx_resources_active ON resources(resource_category) WHERE is_deleted = false;

-- Expenses table
CREATE INDEX idx_expenses_resource_id ON expenses(resource_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date);
CREATE INDEX idx_expenses_is_deleted ON expenses(is_deleted);
CREATE INDEX idx_expenses_resource_date ON expenses(resource_id, expense_date) WHERE is_deleted = false;

-- Resource subscriptions table
CREATE INDEX idx_resource_subscriptions_resource_id ON resource_subscriptions(resource_id);
CREATE INDEX idx_resource_subscriptions_expense_id ON resource_subscriptions(expense_id);
CREATE INDEX idx_resource_subscriptions_dates ON resource_subscriptions(start_date, end_date);
CREATE INDEX idx_resource_subscriptions_status ON resource_subscriptions(status);

-- Supply stock movements table
CREATE INDEX idx_supply_stock_movements_resource_id ON supply_stock_movements(resource_id);
CREATE INDEX idx_supply_stock_movements_expense_id ON supply_stock_movements(expense_id);
CREATE INDEX idx_supply_stock_movements_date ON supply_stock_movements(movement_date);
CREATE INDEX idx_supply_stock_movements_type ON supply_stock_movements(movement_type);

-- Resource unit conversions table
CREATE INDEX idx_resource_unit_conversions_resource_id ON resource_unit_conversions(resource_id);
CREATE INDEX idx_resource_unit_conversions_from_unit ON resource_unit_conversions(from_unit);
CREATE INDEX idx_resource_unit_conversions_to_unit ON resource_unit_conversions(to_unit);

-- Financial accounts table
CREATE INDEX idx_financial_accounts_type ON financial_accounts(account_type);
CREATE INDEX idx_financial_accounts_status ON financial_accounts(status);
CREATE INDEX idx_financial_accounts_is_deleted ON financial_accounts(is_deleted);
CREATE INDEX idx_financial_accounts_active ON financial_accounts(account_type, status) WHERE is_deleted = false;

-- Account transactions table
CREATE INDEX idx_account_transactions_type ON account_transactions(transaction_type);
CREATE INDEX idx_account_transactions_date ON account_transactions(transaction_date);
CREATE INDEX idx_account_transactions_from_account ON account_transactions(from_account_id);
CREATE INDEX idx_account_transactions_to_account ON account_transactions(to_account_id);
CREATE INDEX idx_account_transactions_expense_id ON account_transactions(expense_id);
CREATE INDEX idx_account_transactions_from_date ON account_transactions(from_account_id, transaction_date);
CREATE INDEX idx_account_transactions_to_date ON account_transactions(to_account_id, transaction_date);

-- Utility bills table
CREATE INDEX idx_utility_bills_resource_id ON utility_bills(resource_id);
CREATE INDEX idx_utility_bills_status ON utility_bills(status);
CREATE INDEX idx_utility_bills_due_date ON utility_bills(due_date);
CREATE INDEX idx_utility_bills_bill_date ON utility_bills(bill_date);
CREATE INDEX idx_utility_bills_is_deleted ON utility_bills(is_deleted);
CREATE INDEX idx_utility_bills_status_due_date ON utility_bills(status, due_date) WHERE is_deleted = false;

-- Utility bill payments table
CREATE INDEX idx_utility_bill_payments_bill_id ON utility_bill_payments(bill_id);
CREATE INDEX idx_utility_bill_payments_expense_id ON utility_bill_payments(expense_id);
CREATE INDEX idx_utility_bill_payments_date ON utility_bill_payments(payment_date);

-- Resource status changes table
CREATE INDEX idx_resource_status_changes_resource_id ON resource_status_changes(resource_id);
CREATE INDEX idx_resource_status_changes_status_type ON resource_status_changes(status_type);
CREATE INDEX idx_resource_status_changes_changed_at ON resource_status_changes(changed_at);
CREATE INDEX idx_resource_status_changes_activity ON resource_status_changes(activity);
