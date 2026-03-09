defmodule BookVisuallyWeb.Router do
  use BookVisuallyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BookVisuallyWeb do
    pipe_through :api

    # Dashboard & Overview
    get "/dashboard", DashboardController, :show
    get "/alerts", DashboardController, :alerts
    get "/activity-feed", DashboardController, :activity_feed

    # Resources
    resources "/resources", ResourceController, except: [:new, :edit] do
      get "/history", ResourceController, :history
    end

    # Financial Accounts
    resources "/accounts", AccountController, except: [:new, :edit] do
      get "/history", AccountController, :history
    end

    # Account Transactions
    post "/transactions/deposit", TransactionController, :deposit
    post "/transactions/withdrawal", TransactionController, :withdrawal
    post "/transactions/transfer", TransactionController, :transfer
    post "/transactions/adjustment", TransactionController, :adjustment
    get "/transactions", TransactionController, :index

    # Expenses
    resources "/expenses", ExpenseController, only: [:index, :show]
    post "/expenses/with-payment", ExpenseController, :create_with_payment

    # Supply Stock Movements
    post "/supplies/:id/movements/purchase", SupplyController, :purchase
    post "/supplies/:id/movements/usage", SupplyController, :usage
    post "/supplies/:id/movements/adjustment", SupplyController, :adjustment
    post "/supplies/:id/movements/disposal", SupplyController, :disposal
    post "/supplies/:id/movements/return", SupplyController, :return
    get "/supplies/:id/movements", SupplyController, :movements

    # Utility Bills
    resources "/bills", BillController, except: [:new, :edit]
    post "/bills/:id/pay", BillController, :pay
    get "/bills/overdue", BillController, :overdue
    get "/bills/upcoming", BillController, :upcoming
  end
end
