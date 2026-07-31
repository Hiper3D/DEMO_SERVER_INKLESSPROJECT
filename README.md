# Inkless

**Document Signing & PDF Form Management Platform**

[![Domain](https://img.shields.io/badge/Domain-inkless.bc--pl.com-blue)](https://inkless.bc-pl.com)
[![GitHub](https://img.shields.io/badge/GitHub-Inkless__Project2025-black)](https://github.com/JiteshAI-web/Inkless_Project2025)
[![License](https://img.shields.io/badge/License-AGPLv3-green)](LICENSE)

> Open-source document signing platform based on DocuSeal. Upload documents, create fillable forms, collect electronic signatures, and manage signed documents securely.

**Production:** [https://inkless.bc-pl.com](https://inkless.bc-pl.com)  
**Repository:** [https://github.com/JiteshAI-web/Inkless_Project2025.git](https://github.com/JiteshAI-web/Inkless_Project2025.git)

---

## Features

- Upload and manage PDF documents
- Create fillable PDF forms with drag-and-drop field placement
- Digital / electronic signature support
- User authentication and role-based management
- Email notifications for signing requests and completions
- REST API for integration with other systems
- Database support: PostgreSQL, MySQL, and SQLite
- First-class Docker & Docker Compose support
- Secure storage of signed documents

---

## System Requirements

### Required (Docker Method — Recommended)

| Software        | Purpose                        | Notes                    |
|-----------------|--------------------------------|--------------------------|
| Docker          | Container runtime              | Docker Desktop or Engine |
| Docker Compose  | Multi-container orchestration  | v2+ recommended          |
| Git             | Clone the repository           | Any recent version       |

### Optional (Local Development without Docker)

- **Ruby** — Compatible with Rails version in Gemfile  
- **Rails** — As specified in the project  
- **PostgreSQL** — Recommended for production-like setup  
- **Node.js** — LTS recommended  
- **Yarn** — For frontend asset management  

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/JiteshAI-web/Inkless_Project2025.git
cd Inkless_Project2025
```

### 2. Install with Docker (Recommended)

```bash
# Build and start
docker compose up --build

# Or run in background (detached)
docker compose up -d --build
```

> First build may take several minutes. Subsequent starts are much faster.

### 3. Open the Application

Once containers are running, open your browser:

```
http://localhost:3000
```

Create an admin account on first launch if prompted.

### 4. Stop the Application

```bash
docker compose down

# Also remove volumes (deletes local database data)
docker compose down -v
```

---

## Environment Configuration

Create a `.env` file in the project root if required:

```env
DATABASE_URL=postgresql://username:password@localhost:5432/docuseal
SECRET_KEY_BASE=your_secret_key_here
```

- If no external database is configured, **SQLite** is used by default (ideal for quick local testing).
- For production or multi-user scenarios, configure **PostgreSQL** via `DATABASE_URL`.
- Generate a secure secret key:

```bash
openssl rand -hex 64
```

---

## Local Development Setup (Without Docker)

Use this path when you need to modify application code, debug, or contribute.

### Install Dependencies

```bash
bundle install
yarn install
```

### Setup Database

Ensure PostgreSQL (or your chosen DB) is running, then:

```bash
rails db:create
rails db:migrate
```

### Start the Development Server

```bash
bin/dev
```

or start Rails alone:

```bash
rails server
```

Visit: **http://localhost:3000**

---

## Useful Commands

| Action                              | Command                          |
|-------------------------------------|----------------------------------|
| View running containers             | `docker ps`                      |
| Restart all services                | `docker compose restart`         |
| Follow live logs                    | `docker compose logs -f`         |
| Rebuild after code/Dockerfile changes | `docker compose up --build`    |
| Stop and remove containers          | `docker compose down`            |
| Enter a running container shell     | `docker compose exec web bash`   |

**Common issues**
- **Port 3000 already in use** → Stop the conflicting process or change the mapped port in `docker-compose.yml`.
- **Database connection errors** → Verify `DATABASE_URL` and that the DB container is healthy (`docker compose ps`).

---

## Project Structure

```
Inkless_Project2025/
├── app/                 # Application code (models, controllers, views)
├── config/              # Rails configuration
├── db/                  # Migrations & schema
├── docker/              # Docker-related assets
├── public/              # Static assets
├── storage/             # Uploaded & signed documents
├── docker-compose.yml   # Multi-service definition
├── Dockerfile           # Application image
├── Gemfile              # Ruby dependencies
├── package.json         # JS dependencies
└── README.md            # Project overview
```

---

## Tech Stack

| Layer              | Technology                          |
|--------------------|-------------------------------------|
| Backend            | Ruby on Rails                       |
| Database           | PostgreSQL / MySQL / SQLite         |
| Containerization   | Docker & Docker Compose             |
| Background Jobs    | Redis + Sidekiq                     |
| Frontend           | JavaScript, HTML, CSS               |
| Document Engine    | PDF processing & e-signature        |

---

## Production

Once deployed, the application is available at:

**https://inkless.bc-pl.com**

Ensure reverse proxy (Nginx / Caddy / Traefik), TLS certificates, and environment variables (`SECRET_KEY_BASE`, `DATABASE_URL`, email settings, etc.) are correctly configured. Prefer Docker Compose or a managed container platform for production consistency.

---

## Security Best Practices

- Never commit `.env` files or real secrets to the repository
- Use a strong, unique `SECRET_KEY_BASE` in every environment
- Prefer PostgreSQL over SQLite for multi-user or production deployments
- Keep Docker images and base OS packages updated
- Restrict network access to the database; do not expose it publicly
- Enable HTTPS (TLS) for all production traffic
- Regularly back up the database and the `storage/` directory
- Review and limit user roles; follow least-privilege principles

---

## License

This project is based on [DocuSeal](https://www.docuseal.co/) and is licensed under the **AGPLv3** License.  
See the `LICENSE` file in the repository for full terms.

---

## Links

| Resource        | URL                                                              |
|-----------------|------------------------------------------------------------------|
| Production      | [https://inkless.bc-pl.com](https://inkless.bc-pl.com)           |
| GitHub Repo     | [https://github.com/JiteshAI-web/Inkless_Project2025](https://github.com/JiteshAI-web/Inkless_Project2025) |
| Clone           | `git clone https://github.com/JiteshAI-web/Inkless_Project2025.git` |

---

**Inkless** — Secure document signing, simplified.  
For questions or contributions, open an issue or pull request on the GitHub repository.
