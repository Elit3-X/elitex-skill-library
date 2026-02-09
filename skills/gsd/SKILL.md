---
name: gsd
description: Get Shit Done (GSD) - Project planning and multi-agent execution framework.
---

# Get Shit Done (GSD) Workflow

GSD is a comprehensive framework for multi-agent project planning, execution, and verification. It establishes a structured lifecycle for development tasks, ensuring that every piece of work is properly planned, researched, executed, and verified.

## Core Principles

1.  **Spec-Driven Development**: Work starts with clear requirements and a roadmap.
2.  **Multi-Agent Orchestration**: Specialised agents for planning, research, execution, and verification.
3.  **Scientific Debugging**: Systematic issue investigation with persistent state.
4.  **Continuous Alignment**: Regular progress tracking and milestone auditing.

## Command Reference

### Initialization & Planning
- `/gsd:new-project`: Initialize a new project with research, requirements, and roadmap.
- `/gsd:map-codebase`: Analyze and map an existing codebase.
- `/gsd:plan-phase <N>`: Create a detailed execution plan for a specific phase.
- `/gsd:discuss-phase <N>`: Articulate vision for a phase before planning.

### Execution & Management
- `/gsd:execute-phase <N>`: Execute all plans in a phase using parallel task runners.
- `/gsd:quick`: Execute small, ad-hoc tasks with GSD guarantees.
- `/gsd:progress`: Check project status and route to the next action.
- `/gsd:resume-work`: Restore context and resume from the previous session.
- `/gsd:pause-work`: Create a context handoff for pausing work mid-phase.

### Quality & Maintenance
- `/gsd:debug [issue]`: Systematic debugging with persistent state.
- `/gsd:verify-work [phase]`: Validate built features through conversational UAT.
- `/gsd:audit-milestone`: Audit completion against original requirements.
- `/gsd:add-todo [desc]`: Capture ideas or tasks during development.

## File Structure

GSD maintains project state in the `.planning/` directory:
- `PROJECT.md`: Vision and core requirements.
- `ROADMAP.md`: Phase breakdown and status.
- `STATE.md`: Project memory and session continuity.
- `REQUIREMENTS.md`: Scoped requirement definitions.
- `phases/`: Detailed plans and execution summaries.

## Usage in Antigravity

When this skill is active, you can use the `/gsd:` commands to manage your project lifecycle. The system automatically maintains state and ensures that all work follows the GSD methodology.
