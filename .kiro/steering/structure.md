---
inclusion: always
---

# Project Structure

This is a monorepo with separate frontend and backend applications.

## Directory Layout

```
bookvisually/
├── frontend/           # React + Vite application
│   ├── src/
│   │   ├── App.jsx    # Main application component
│   │   ├── main.jsx   # Application entry point
│   │   ├── assets/    # Static assets (images, icons)
│   │   ├── App.css    # Component styles
│   │   └── index.css  # Global styles
│   ├── public/        # Public static files
│   ├── package.json   # Frontend dependencies
│   └── vite.config.js # Vite configuration
│
├── backend/           # Elixir + Phoenix application
│   └── (to be implemented)
│
├── README.md          # Project documentation
└── GUIDELINES.md      # Development guidelines
```

## Organization Principles

- Monorepo structure with clear separation between frontend and backend
- Each application is self-contained with its own dependencies
- Frontend follows standard React + Vite project structure
- Backend will follow Phoenix framework conventions

## Working Directory Rules

When modifying or running commands:
- Frontend work: Always use `frontend/` as working directory
- Backend work: Always use `backend/` as working directory
- Never execute application-specific commands from project root
