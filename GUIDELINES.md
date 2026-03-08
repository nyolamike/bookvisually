# Development Guidelines

## Monorepo Structure

This project is organized as a monorepo with separate frontend and backend folders.

### Frontend Commands

All frontend-related commands MUST be executed from the `frontend/` directory.

**Examples:**
```bash
# ✅ Correct
cd frontend
npm install
npm run dev

# ❌ Incorrect
npm install  # Running from root
```

**When working with the frontend:**
1. Always verify you are in the `frontend/` directory before running npm/node commands
2. Use `cd frontend` or specify `cwd: frontend` when executing commands
3. Frontend dependencies are managed in `frontend/package.json`

### Backend Commands

All backend-related commands MUST be executed from the `backend/` directory.

**Examples:**
```bash
# ✅ Correct
cd backend
mix deps.get
mix phx.server

# ❌ Incorrect
mix deps.get  # Running from root
```

**When working with the backend:**
1. Always verify you are in the `backend/` directory before running mix/elixir commands
2. Use `cd backend` or specify `cwd: backend` when executing commands
3. Backend dependencies are managed in `backend/mix.exs`

## For AI Assistants

When executing commands:
- Check the context of the command (frontend vs backend)
- Always specify the correct working directory
- Verify the folder exists before running commands
- If unsure, ask for clarification about which part of the project the command targets
