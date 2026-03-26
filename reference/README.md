# Getting Started: Local Development & Deployment

This guide covers how to set up and run the reference implementation locally.

## Prerequisites

- Docker
- Docker Compose
- Amazon Bedrock with the ability to create inference profiles and guardrails (for LLM access)
- uv - [Installation Guide](https://docs.astral.sh/uv/getting-started/installation/#installing-uv)
- Python 3.13 or higher - We recommend using uv to manage your Python environment.
- Git

## Repositories

| Service | Type | Language |
|---------|------|----------|
| [ai-uc-content-swarm-ui](https://github.com/DEFRA/ai-uc-content-swarm-ui) | Frontend | JavaScript |
| [ai-uc-content-swarm-runtime](https://github.com/DEFRA/ai-uc-content-swarm-runtime) | Backend/Runtime | Python |

## Local Development

You will need to clone this repository and sync the environment before running the scripts.

By default, service repositories are cloned into the parent directory of `ai-uc-content-swarm-core`. Therefore, we recommend creating a directory specifically for the AI UC Content Swarm project and cloning all repositories into it.

```bash
git clone https://github.com/DEFRA/ai-uc-content-swarm

cd ai-uc-content-swarm/

uv sync --frozen
```

### Cloning Repositories

This project contains a script to clone all the required repositories. This works by checking the service-compose directory for the services and cloning them if they do not exist.

To clone the repositories, run the following command:

```bash
uv run task clone
```

Your cloned repositories will be located in the `ai-uc-content-swarm` directory created in the previous step.

### Environment Configuration
This repository uses a `.env` file for environment variable configuration. This must be created for the Docker Compose project to start.

> [!IMPORTANT]
> The `.env` file should not be committed to version control. Add it to your `.gitignore` file to keep sensitive configuration data secure.

There is an example environment file located at `.env.example`. You can create your own `.env` file by copying the example file:
```bash
cp .env.example .env
```

Refer to the table below for environment variables, their defaults, and whether they're required by the services.

| Variable | Default | Required | Description |
|---|---|:---:|---|
| AWS_REGION | eu-west-2 | No | Primary AWS region used by services (runtime default: `eu-west-2`) |
| AWS_DEFAULT_REGION | eu-west-2 | No | Fallback AWS region environment variable |
| AWS_ACCESS_KEY_ID | test | No | AWS access key (use local/test credentials for local dev) |
| AWS_SECRET_ACCESS_KEY | test | No | AWS secret key (use local/test credentials for local dev) |
| AWS_EMF_ENVIRONMENT | local | No | Environment label for EMF (embedded metrics) |
| AWS_EMF_AGENT_ENDPOINT | tcp://127.0.0.1:25888 | No | EMF agent endpoint for metrics ingestion |
| AWS_EMF_LOG_GROUP_NAME | log-group-name | No | CloudWatch EMF log group name (local placeholder) |
| AWS_EMF_LOG_STREAM_NAME | log-stream-name | No | CloudWatch EMF log stream name (local placeholder) |
| AWS_EMF_NAMESPACE | namespace | No | EMF metrics namespace |
| AWS_EMF_SERVICE_NAME | service-name | No | Logical service name for EMF metrics |
| AWS_EMF_SERVICE_TYPE | python-backend-service | No | Service type used by EMF instrumentation |
| AWS_BEARER_TOKEN_BEDROCK | (empty) | No | Optional bearer token for Bedrock API access |
| CLAUDE_HAIKU_MODEL_CONFIG | {model_id},{inference_profile},{guardrail_id}:{guardrail_version} | Yes | Bedrock model config string for the `claude_haiku` model (runtime requires this format). |
| CLAUDE_SONNET_MODEL_CONFIG | {model_id},{inference_profile},{guardrail_id}:{guardrail_version} | Yes | Bedrock model config string for the `claude_sonnet` model (runtime requires this format). |
| CONTEXT_BUCKET | ai-uc-content-swarm-context | Yes | S3 bucket name used for storing context files (required by runtime: `CONTEXT_BUCKET`) |
| HOST_URL | (none) | Yes | Public callback base URL used by the runtime (`HOST_URL` / `callback_base` in `app/config.py`) |
| CDP_UPLOADER_BASE_URL | (none) | Yes | Base URL used by CDP uploader (`CDP_UPLOADER_BASE_URL` required by runtime config) |
| UPLOADER_URL | (none) | No | Local uploader service URL (used by other scripts / UI as fallback) |
| RUNTIME_URL | (none) | No | Runtime service base URL used by the UI (`RUNTIME_URL`) |
| SWARM_INVOKE_QUEUE_URL | (none) | Yes | Local SQS queue URL used for swarm invocations (required by `SwarmInvokeQueueConfig`) |

### Preparing Design Rule Context

The `/notebooks` directory contains Jupyter notebooks used for loading GOV.UK content and style guide and produce the reference documents used by the Writer and Critic agents in the swarm. These notebooks only need to be run when setting up the project for the first time, or when the reference documents need to be updated.

#### Running the Notebooks

The notebooks have their own `pyproject.toml` with seperate dependencies from the runtime. Install them and register the Jupyter kernel with the following commands:

```bash
cd notebooks/

uv sync --locked

un run task create-kernel
```

Then you can either open the notebooks in your IDE or start a Jupyter server with:

```bash
uv run --with jupyter jupyter lab
```

### `content-guidance.ipynb`

Loads guidance pages from [GOV.UK Content Design Guidance](https://www.gov.uk/guidance/content-design) and produces markdown files covering:
- Content types
- How to write for GOV.UK
- Content design patterns and approaches

This is outputted to `notebooks/outputs/content-guidance/` with the following tree:
```
content-guidance/
├── index.json          # Discovery index (id, title, description, file path)
|── content-types/
    ├── *.md            # One file per content type ection
├── *.md                # Top level guidance documents, split by section
```

Each file included YAML frontmatter (`title`, `description`, `source_url`) followed by the page content as markdown.

### `content-style-guide.ipynb`

Loads the [GOV.UK Style Guide](https://www.gov.uk/guidance/style-guide) and produces markdown documents covering:
- Rules covering how to write specific elements (dates, numbers, etc.)
- Rules covering tone and style (e.g. use of acronyms, capitalisation, etc.)
- A dictionary of common terms and their preferred usage on GOV.UK

This is outputted to `notebooks/outputs/content-style-guide/` with the following tree:
```
content-style-guide/
├── index.json          # Discovery index (title, type, file path)
├── a-to-z/
│   ├── [0-9a-z].md     # One file per letter (a-z) and number (1)
│   └── rules/
│       ├── *.md        # Individual style rules (e.g., capitalisation.md, dates.md, etc.)
├── *.md                # Top level style guide documents, split by section
```

Each file includes YAML frontmatter (`title`, `description`, `source_url`) followed by the page content as markdown.

### Starting the Services

A single docker-compose project has been created that orchestrates all microservices, dependencies, and performs any necessary setup tasks such as database migrations.

All configuration is stored in the `.env` file. Before starting the services, ensure that the `.env` file is correctly configured. The services will use default values if no `.env` file is present.

To start all services, run the following command:

```bash
docker-compose up --build
```

To stop the services, run the following command:

```bash
docker-compose down
```

The services can still be started individually directly from their respective repositories. However, this project is intended to streamline local development by having a common entry point for all services.

## Network

All services run on a shared Docker network named `ai-uc-content-swarm` to enable inter-service communication.

## Script Documentation

This project contains a number of scripts to streamline local microservice development.

### Clone

Clones the repositories for each microservice into the parent directory.

```bash
uv run task clone
```

### Pull

Pulls the latest remote changes for each microservice.

```bash
uv run task pull
```

### Update

Switches to and pulls the latest main branch for each microservice.

```bash
uv run task update
```
