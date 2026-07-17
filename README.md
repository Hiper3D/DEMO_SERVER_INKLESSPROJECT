# DocuSeal

DocuSeal is an open-source document signing and PDF form management platform. It allows users to upload documents, create fillable forms, collect electronic signatures, and manage signed documents securely.

---

## Features

- Upload and manage PDF documents
- Create fillable PDF forms
- Digital signature support
- User authentication and management
- Email notifications
- REST API support
- PostgreSQL/MySQL/SQLite database support
- Docker support

---

# System Requirements

Before installing the project, make sure the following software is installed:

- Docker
- Docker Compose
- Git

(Optional for local development)

- Ruby
- Rails
- PostgreSQL
- Node.js
- Yarn

---

# Clone the Repository

```bash
git clone https://github.com/docusealco/docuseal.git
cd docuseal
```

---

# Installation

## Using Docker (Recommended)

### Build and Start the Application

```bash
docker compose up --build
```

or

```bash
docker-compose up --build
```

To run in the background:

```bash
docker compose up -d
```

---

# Environment Configuration

If required, create a `.env` file.

Example:

```env
DATABASE_URL=postgresql://username:password@localhost:5432/docuseal
SECRET_KEY_BASE=your_secret_key
```

If no database is configured, DocuSeal uses SQLite by default.

---

# Running the Project

Once the containers are running, open your browser and visit:

```
http://localhost:3000
```

---

# Stop the Application

```bash
docker compose down
```

---

# Running Without Docker (Development)

## Install Dependencies

```bash
bundle install
yarn install
```

## Setup Database

```bash
rails db:create
rails db:migrate
```

## Start the Rails Server

```bash
bin/dev
```

or

```bash
rails server
```

Visit:

```
http://localhost:3000
```

---

# Useful Commands

### View Running Containers

```bash
docker ps
```

### Restart Containers

```bash
docker compose restart
```

### View Logs

```bash
docker compose logs -f
```

### Rebuild Containers

```bash
docker compose up --build
```

---

# Project Structure

```
docuseal/
│
├── app/
├── config/
├── db/
├── docker/
├── public/
├── storage/
├── docker-compose.yml
├── Dockerfile
├── Gemfile
├── package.json
└── README.md
```

---

# Tech Stack

- Ruby on Rails
- PostgreSQL / SQLite
- Docker
- Redis
- Sidekiq
- JavaScript
- HTML/CSS

---

# Default URL

```
http://localhost:3000
```

---

# License

This project is licensed under the AGPLv3 License.
