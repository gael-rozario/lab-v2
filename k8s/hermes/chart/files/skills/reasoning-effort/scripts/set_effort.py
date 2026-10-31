#!/opt/hermes/.venv/bin/python3
"""Show or set the reasoning effort Hermes sends to its LLM endpoint.

Hermes' /reasoning command is not forwarded to custom endpoints, so effort is
steered via chat_template_kwargs.reasoning_effort in the provider entry's
extra_body in $HERMES_HOME/config.yaml. Hermes reads that when it builds the
agent for a session, so a change applies from the next session (/new).

Usage: set_effort.py show | low | medium | high | xhigh
Shipped by IaC (k8s/hermes chart); a pod restart resets to the terragrunt value.
Runs on Hermes' venv python: the image has no PyYAML, only Hermes' ruamel.yaml
(round-trip mode also keeps the file's existing formatting).
"""
import os
import sys
import tempfile

from ruamel.yaml import YAML

yaml = YAML()  # round-trip
yaml.default_flow_style = False

# The qwen chat template only knows low / medium / xhigh.
ALIASES = {"minimal": "low", "low": "low", "medium": "medium",
           "high": "xhigh", "xhigh": "xhigh", "max": "xhigh"}

path = os.path.join(os.environ.get("HERMES_HOME", "/opt/data"), "config.yaml")


def norm(url):
    return (url or "").strip().rstrip("/").lower()


def matching_entries(cfg):
    """Provider entries pointing at the main model's base_url, in either the
    current `providers:` dict or the legacy `custom_providers:` list."""
    target = norm((cfg.get("model") or {}).get("base_url"))
    found = []
    for entry in (cfg.get("providers") or {}).values():
        if isinstance(entry, dict) and norm(entry.get("api") or entry.get("base_url")) == target:
            found.append(entry)
    for entry in cfg.get("custom_providers") or []:
        if isinstance(entry, dict) and norm(entry.get("base_url")) == target:
            found.append(entry)
    return target, found


def current(entries):
    for e in entries:
        v = ((e.get("extra_body") or {}).get("chat_template_kwargs") or {}).get("reasoning_effort")
        if v:
            return v
    return None


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    arg = sys.argv[1].strip().lower()

    with open(path) as f:
        cfg = yaml.load(f) or {}
    target, entries = matching_entries(cfg)
    if not target:
        sys.exit("set_effort: config.yaml has no model.base_url; nothing to configure")

    old = current(entries)
    if arg == "show":
        print(f"reasoning_effort: {old or 'unset (llama-cpp server default: medium)'}")
        return
    if arg not in ALIASES:
        sys.exit(f"set_effort: unknown level {arg!r}; use one of: show, {', '.join(ALIASES)}")
    level = ALIASES[arg]

    if not entries:
        # No provider entry yet: create one bound to the main endpoint.
        entry = {"name": "litellm", "api": target}
        cfg.setdefault("providers", {})["litellm"] = entry
        entries = [entry]
    for e in entries:
        e.setdefault("extra_body", {}).setdefault("chat_template_kwargs", {})["reasoning_effort"] = level

    # Atomic write, keeping the file's mode/owner semantics (same dir, replace).
    mode = os.stat(path).st_mode & 0o777
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".config.yaml.")
    try:
        with os.fdopen(fd, "w") as f:
            yaml.dump(cfg, f)
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    except BaseException:
        os.unlink(tmp)
        raise

    note = f" (requested {arg!r}, template maps it to {level!r})" if arg != level else ""
    print(f"reasoning_effort: {old or 'unset'} -> {level}{note}")
    print("Takes effect from the next session: send /new. Resets to the IaC default on pod restart.")


if __name__ == "__main__":
    main()
