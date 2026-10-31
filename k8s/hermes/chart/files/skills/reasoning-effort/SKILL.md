---
name: reasoning-effort
description: "Show or change how hard the LLM thinks (reasoning effort: low/medium/xhigh)."
version: 1.0.0
author: Gael (IaC-managed, k8s/hermes chart)
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [Configuration, Reasoning, Effort, LLM]
    related_skills: []
---

# Reasoning Effort

## When to use

Use when Gael asks to change, raise, lower, or check the reasoning / thinking
effort, e.g. "set effort low", "think harder", "use xhigh", "/effort medium",
"what effort are you on?".

Do NOT use the built-in `/reasoning` command for this: it is silently ignored
for this deployment's custom LLM endpoint. This skill is the working path.

## How

Run with the `terminal` tool (no setup needed). Use exactly this interpreter:
the system `python3` lacks the YAML library the script needs.

```bash
/opt/hermes/.venv/bin/python3 /opt/data/skills/devops/reasoning-effort/scripts/set_effort.py show
/opt/hermes/.venv/bin/python3 /opt/data/skills/devops/reasoning-effort/scripts/set_effort.py <level>
```

Levels: `low`, `medium`, `xhigh`. `high`/`max` map to `xhigh` and `minimal`
maps to `low` (the model's chat template only supports low/medium/xhigh).

Pass only one of those level words as the argument, never anything else.

## After changing

Relay the script's output, then tell Gael the new level applies from the
**next session**: he needs to send `/new` (the current session keeps the
level it started with). Also mention that a pod restart resets it to the
default set in IaC (`reasoning_effort` in `k8s/hermes/terragrunt.hcl`); to
change the default permanently, that file is the place.

Rough guide: `low` is ~30% faster on typical questions; `xhigh` is for hard
multi-step debugging and can take minutes per reply.
