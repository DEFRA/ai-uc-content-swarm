# Agent Architecture

This document provides zoomed-in architecture diagrams for each agent in the content swarm, showing the tools available to each agent, the services and repositories they interact with, and the underlying infrastructure.

See also: [Context Types](context-types.md) for a breakdown of the data each agent works with.

---

## Manager Agent

The orchestrator and entry point for the swarm. Routes tasks to appropriate sub-agents and maintains the shared conversation context.

```mermaid
graph TD
    MA["<b>Manager Agent</b><br/>Orchestrator &amp; Task Dispatcher<br/>LLM: Claude Sonnet"]

    T1["<b>dispatch(agent_name, task)</b><br/>Route task to named sub-agent<br/>and track responses"]

    GC["<b>Group Chat</b><br/>Shared conversation transcript<br/>&amp; agent exchanges"]

    HIST["<b>Context History</b><br/>Per-agent message history<br/>for LLM context"]

    DEPS["<b>Dependencies</b><br/>• Prompt Repository<br/>• Run Config<br/>• LLM Mapping"]

    MA -->|Uses| T1
    MA -->|Reads/writes to| GC
    MA -->|Manages| HIST
    MA -->|Accesses| DEPS

    style MA fill:#4A90E2,stroke:#2E5C8A,color:#fff,stroke-width:3px
    style T1 fill:#E8F4F8,stroke:#4A90E2,color:#000,stroke-width:2px
    style GC fill:#FFF9C4,stroke:#F57F17,color:#000,stroke-width:2px
    style HIST fill:#FFF9C4,stroke:#F57F17,color:#000,stroke-width:2px
    style DEPS fill:#F0F0F0,stroke:#666,color:#000,stroke-width:2px
```

**Key characteristics:**
- Single tool: `dispatch` — delegates all substantive work to sub-agents
- Maintains the shared group chat transcript for context across agent turns
- Tracks per-agent message history to manage LLM context windows
- No direct access to content pages, policy documents, or style guides

---

## Researcher Agent

Analyzes uploaded policy documents and extracts key information needed by other agents.

```mermaid
graph TD
    RA["<b>Researcher Agent</b><br/>Policy Analysis &amp; Context Extraction<br/>LLM: Claude Haiku"]

    T1["<b>list_policy_documents()</b><br/>List available policy docs<br/>from run configuration"]

    T2["<b>get_document_content(context_id)</b><br/>Retrieve full document text<br/>by ID"]

    RC["<b>Run Config</b><br/>context_documents:<br/>• id<br/>• name<br/>• type<br/>• path"]

    REPO["<b>Context Repository</b><br/>(S3-backed)<br/>Retrieves documents<br/>by path"]

    S3["<b>AWS S3</b><br/>Context Bucket"]

    RA -->|Calls| T1
    RA -->|Calls| T2
    T1 -->|Reads from| RC
    T2 -->|Queries| REPO
    REPO -->|Fetches from| S3

    style RA fill:#7CB342,stroke:#558B2F,color:#fff,stroke-width:3px
    style T1 fill:#E8F4E8,stroke:#7CB342,color:#000,stroke-width:2px
    style T2 fill:#E8F4E8,stroke:#7CB342,color:#000,stroke-width:2px
    style RC fill:#FFF9C4,stroke:#F57F17,color:#000,stroke-width:2px
    style REPO fill:#FFF9C4,stroke:#F57F17,color:#000,stroke-width:2px
    style S3 fill:#FFCCBC,stroke:#E64A19,color:#000,stroke-width:2px
```

**Key characteristics:**
- Read-only access to policy documents provided at run time via the SQS job payload
- Uses Claude Haiku — suited to structured information extraction at lower cost
- No access to content creation or GOV.UK style/guidance documents
- Output flows to other agents via the shared group chat

---

## Writer Agent

Generates initial content drafts based on researcher insights and GOV.UK guidelines.

```mermaid
graph TD
    WA["<b>Writer Agent</b><br/>Content Creation &amp; Drafting<br/>LLM: Claude Sonnet"]

    subgraph CT["Content Page Tools"]
        T1["<b>create_page(page_key, content)</b>"]
        T2["<b>update_page(page_key, content)</b>"]
        T3["<b>list_pages()</b>"]
        T4["<b>read_page(page_key)</b>"]
    end

    subgraph GT["Guidance &amp; Reference Tools"]
        T5["<b>list_style_guide_documents()</b>"]
        T6["<b>list_content_guidance()</b>"]
        T7["<b>get_document_content(file)</b>"]
    end

    CONTENT_REPO["<b>Content Pages Repository</b><br/>(S3-backed)<br/>Path: runs/{run_id}/<br/>content-pages/{page_key}.md"]

    CONTEXT_REPO["<b>Context Repository</b><br/>(S3-backed)<br/>GOV.UK Style Guide<br/>GOV.UK Content Guidance"]

    S3_CONTENT["<b>AWS S3</b><br/>Content Pages Bucket"]
    S3_CONTEXT["<b>AWS S3</b><br/>Context Bucket"]

    WA -->|Uses| CT
    WA -->|Uses| GT
    CT -->|Persist to| CONTENT_REPO
    GT -->|Queries| CONTEXT_REPO
    CONTENT_REPO -->|Stores in| S3_CONTENT
    CONTEXT_REPO -->|Reads from| S3_CONTEXT

    style WA fill:#EC407A,stroke:#C2185B,color:#fff,stroke-width:3px
    style CT fill:#F8E8F4,stroke:#EC407A,color:#000,stroke-width:2px
    style GT fill:#F8E8F4,stroke:#EC407A,color:#000,stroke-width:2px
    style CONTENT_REPO fill:#FFF9C4,stroke:#F57F17,color:#000,stroke-width:2px
    style CONTEXT_REPO fill:#FFF9C4,stroke:#F57F17,color:#000,stroke-width:2px
    style S3_CONTENT fill:#FFCCBC,stroke:#E64A19,color:#000,stroke-width:2px
    style S3_CONTEXT fill:#FFCCBC,stroke:#E64A19,color:#000,stroke-width:2px
```

**Key characteristics:**
- Full content lifecycle: create and update pages (Critic has read-only)
- Supports multiple pages per run: a `main` page plus optional `sub/<slug>` pages
- Real-time access to GOV.UK style guides and content guidance during drafting
- All created/updated content is persisted immediately to S3

---

## Critic Agent

Reviews generated content against GOV.UK guidelines and provides improvement feedback.

```mermaid
graph TD
    CA["<b>Critic Agent</b><br/>Content Review &amp; Assessment<br/>LLM: Claude Sonnet"]

    subgraph RT["Review Tools"]
        T1["<b>list_pages()</b>"]
        T2["<b>read_page(page_key)</b>"]
    end

    subgraph GT["Guidance &amp; Reference Tools"]
        T3["<b>list_style_guide_documents()</b>"]
        T4["<b>list_content_guidance()</b>"]
        T5["<b>get_document_content(file)</b>"]
    end

    CONTENT_REPO["<b>Content Pages Repository</b><br/>(S3-backed)<br/>Reads generated content<br/>for review"]

    CONTEXT_REPO["<b>Context Repository</b><br/>(S3-backed)<br/>GOV.UK Style Guide<br/>GOV.UK Content Guidance"]

    S3_CONTENT["<b>AWS S3</b><br/>Content Pages Bucket"]
    S3_CONTEXT["<b>AWS S3</b><br/>Context Bucket"]

    CA -->|Uses| RT
    CA -->|Uses| GT
    RT -->|Reads from| CONTENT_REPO
    GT -->|Queries| CONTEXT_REPO
    CONTENT_REPO -->|Fetches from| S3_CONTENT
    CONTEXT_REPO -->|Reads from| S3_CONTEXT

    style CA fill:#29B6F6,stroke:#0277BD,color:#fff,stroke-width:3px
    style RT fill:#E1F5FE,stroke:#29B6F6,color:#000,stroke-width:2px
    style GT fill:#E1F5FE,stroke:#29B6F6,color:#000,stroke-width:2px
    style CONTENT_REPO fill:#FFF9C4,stroke:#F57F17,color:#000,stroke-width:2px
    style CONTEXT_REPO fill:#FFF9C4,stroke:#F57F17,color:#000,stroke-width:2px
    style S3_CONTENT fill:#FFCCBC,stroke:#E64A19,color:#000,stroke-width:2px
    style S3_CONTEXT fill:#FFCCBC,stroke:#E64A19,color:#000,stroke-width:2px
```

**Key characteristics:**
- Read-only access to content pages — cannot create or modify content directly
- Same guidance toolset as the Writer, enabling independent standards verification
- Feedback is returned as output to the group chat for the Writer to act on
- Uses Claude Sonnet for nuanced quality evaluation

---

## Infrastructure & Data Storage

All agents interact with three core service repositories:

| Repository | Backed By | Purpose | Writer | Critic | Researcher | Manager |
|---|---|---|:---:|:---:|:---:|:---:|
| **Content Pages** | AWS S3 | Stores generated markdown content | Read/Write | Read | — | — |
| **Context** | AWS S3 | Style guides, content guidance, policy docs | Read | Read | Read | — |
| **Prompts** | Filesystem | Agent system instructions | Read | Read | Read | Read |

S3 object path for content pages: `runs/{run_id}/content-pages/{page_key}.md`
