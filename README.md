# Use Case: Automating GOV.UK Guidance Content Drafting

## The problem

Drafting new GOV.UK guidance can be slow and specialist-heavy work. At a minimum, it requires people who can:
- Read and interpret policy documents and user needs
- Translate them into plain English at the right level for the audience
- Critically review the draft against GDS standards and guidelines

In practice, that means coordinating across multiple people in a team, sometimes multiple teams, with multiple rounds of review and iteration before the content is ready to publish. The bottleneck is rarely a lack of skills in the team, but rather the time and effort required to convert complex information into clear, compliant content.

## The approach

This use case demonstrates how a **swarm** of LLM agents could be designed to take on the different tasks / roles in the process. Working collaboratively, just like a team of specialists would.

Each agent in the swarm has a specific role and a defined set of capabilities. The **manager** agent acts as a lightweight orchestrator / supervisor, routing taks to the right agent at the right time, but without doing deep reasoning or content generation itself.

The swarm works through the task collabartively, including the following roles:
- The **Researcher** reads the user uploaded policy documents and extracts the key information that the other members of the swarm will need to know
- The **Writer** takes the researcher's findings and drafts GOV.UK-compliant content, referencing the GOV.UK style guide and content design guidance as needed
- The **Critic** reviews the draft content against the same guidance and provides feedback for improvement

All agents contribute their outputs to a shared group chat, which maintains the common context and conversation history for the swarm. This also allows the human leading the process to see the full history of the swarm's work and in a future iteration could allow for more collaborative interactions between the agents. The manager can refer to this shared context when making decisions about routing and task management, but does not rely on it for deep reasoning or content generation.

## What is needed to use it?

- One or more policy documents (text or ideally markdown files) to base the content on
- A clear idea of the intended audience and their needs (e.g. users of a specific service, or users with a specific need)
- A content designer to lead the process and review the outputs, providing feedback and guidance to the swarm as needed

## Further reading

### Reference implementation
The reference implementation (targeted towards developers) for this use case can be found in the [GOV.UK Guidance Content Swarm](https://github.com/DEFRA/ai-uc-content-swarm)

### Proof of concepts
Before building the pattern and the use case, we built a number of proof of concepts to test different aspects of the design. PoCs for this use case are as follows:
- [ai-agent-swarm-spike](https://github.com/DEFRA/ai-spike-agent-swarm)

### Tech Patterns Used

This use case is built upon the following technical patterns:
- [Async LLM Inference](https://github.com/DEFRA/ai-tech-pattern-async-inference)
- [AI Frameworks](https://github.com/DEFRA/ai-tech-pattern-ai-frameworks)
