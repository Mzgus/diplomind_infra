# Diplomind Project Overview

Diplomind is an educational platform designed to manage student skill acquisition and validation. It allows administrators to manage users and courses, teachers to create projects and validate skills, and students to track their progress.

## Architecture

The project is structured as a monorepo with two main components:
- **`diplomind_be/`**: A REST API backend written in Rust.
- **`diplomind_fe/`**: A modern web frontend built with React and TypeScript.

Infrastructure and orchestration are managed via Docker Compose and `just`.

## Technology Stack

### Backend (`diplomind_be`)
- **Language:** Rust (Edition 2024)
- **Web Framework:** [Poem](https://docs.rs/poem/latest/poem/)
- **Database:** PostgreSQL with [SQLx](https://docs.rs/sqlx/0.8.6/sqlx/) (async queries)
- **Async Runtime:** [Tokio](https://docs.rs/tokio/1.49.0/tokio/)
- **Authentication:** JWT ([jsonwebtoken](https://docs.rs/jsonwebtoken/10.2.0/jsonwebtoken/)) & Refresh Tokens (Cookie-based)
- **Security:** Argon2 for password hashing
- **Error Handling:** [thiserror](https://docs.rs/thiserror/2.0.17/thiserror/)
- **Serialization:** [serde](https://docs.rs/serde/1.0.228/serde/)

### Frontend (`diplomind_fe`)
- **Framework:** React 19
- **Language:** TypeScript
- **Build Tool:** Vite
- **Styling:** Tailwind CSS 4
- **Routing:** React Router 7
- **HTTP Client:** Axios
- **Auth:** Context-based auth with JWT decode and secure storage

### Infrastructure
- **Containerization:** Docker & Docker Compose
- **Command Runner:** [just](https://github.com/casey/just)

## Getting Started

### Prerequisites
- Docker & Docker Compose
- Rust toolchain (for backend development)
- Node.js & npm (for frontend development)
- `just` (optional but recommended)

### Configuration
1. Copy `.env.template` to `.env` in the root and in `diplomind_be/`.
2. Configure the database and security variables.

### Common Commands

#### Orchestration (Root)
- `just build`: Build and start all services in Docker.
- `just up`: Start all services.
- `just down`: Stop all services.
- `just seed`: Inject test data into the database.
- `just wipe`: Reset the database volume and restart.

#### Backend (`diplomind_be/`)
- `cargo run`: Run the API server locally.
- `cargo test`: Run all backend tests.
- `cargo test -- --nocapture`: Run tests with stdout enabled.

#### Frontend (`diplomind_fe/`)
- `npm run dev`: Start the development server.
- `npm run build`: Build for production.
- `npm run lint`: Run ESLint.

## Development Conventions

### Backend
- **Surgical Updates:** When modifying handlers or database logic, ensure changes are idiomatic and type-safe.
- **Database:** Use SQLx macros for query validation where possible. Migrations are located in `diplomind_be/mig/`.
- **Errors:** Use the custom error types defined in `errors.rs`.
- **RBAC:** Strictly adhere to the role-based access control (Admin, Teacher, Student) implemented in the middleware.

### Frontend
- **Components:** Use functional components with hooks.
- **Styling:** Use Tailwind CSS utility classes.
- **State Management:** Use React Context for global state (Auth, Theme).
- **API Calls:** Use the services defined in `_services/` to interact with the backend.

### General
- **Security:** Never commit `.env` files. Use the provided templates.
- **Testing:** Always run existing tests before and after making changes. Add new tests for new features.
