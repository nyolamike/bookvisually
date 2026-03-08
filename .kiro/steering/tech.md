---
inclusion: always
---

# Technology Stack

## Frontend

- React 19.2 (JavaScript, no TypeScript)
- Vite 8.0 (build tool with HMR)
- Tailwind CSS (styling)
- React Flow (@xyflow/react) (interactive diagrams)
- ESLint (linting)

## Backend

- Elixir + Phoenix (web framework)
- PostgreSQL (database)
- Event-driven architecture

## Common Commands

### Frontend Commands

All frontend commands must be run from the `frontend/` directory:

```bash
cd frontend
npm install          # Install dependencies
npm run dev          # Start development server
npm run build        # Build for production
npm run lint         # Run ESLint
npm run preview      # Preview production build
```

### Backend Commands

All backend commands must be run from the `backend/` directory:

```bash
cd backend
mix deps.get         # Install dependencies
mix phx.server       # Start Phoenix server
```

## Critical Rules

- Always specify the correct working directory when running commands
- Frontend uses `npm`, backend uses `mix`
- Never run frontend commands from project root
- Never run backend commands from project root
