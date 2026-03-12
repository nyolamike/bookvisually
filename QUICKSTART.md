# BookVisually - Quick Start Guide

## Prerequisites

- Elixir + Phoenix (backend)
- Node.js + npm (frontend)
- PostgreSQL (database)

## Setup & Run

### 1. Backend Setup

```bash
cd backend
mix deps.get
mix ecto.setup
mix phx.server
```

Backend runs at: http://localhost:4000

### 2. Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

Frontend runs at: http://localhost:5173

## First Steps

1. Open http://localhost:5173 in your browser
2. Click "Add Account" to create your first account
3. Click on an account node to deposit money
4. Watch the balance update in real-time!

## What's Working

✅ Visual canvas with React Flow
✅ Create bank accounts, cash accounts, funding lines
✅ Deposit money and see balances update
✅ Dashboard showing total balance and cash flow
✅ Drag nodes to organize your canvas
✅ Full backend API with 40+ endpoints ready

## Architecture

- **Frontend**: React 19.2 + Vite + Tailwind + React Flow
- **Backend**: Elixir + Phoenix + PostgreSQL
- **API**: RESTful with batch operations for atomic transactions

## Next Features to Build

- Resource creation (supplies, assets, subscriptions, utilities)
- Expense tracking with payment flow
- Bill management
- Transfer between accounts
- Money flow animations
- Activity feed
- Resource history views
