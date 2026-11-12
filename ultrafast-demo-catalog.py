#!/usr/bin/env python3
"""Refresh demo-only speed metadata from the installed CLI's bundled catalog."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    result = subprocess.run(
        ["codex", "debug", "models", "--bundled"],
        capture_output=True, text=True, timeout=30, check=True,
    )
    catalog = json.loads(result.stdout)
    found = set()
    for model in catalog["models"]:
        # These models support Ultrafast in the public Responses API.
        if model.get("slug") not in {"gpt-6.1-sol", "gpt-6-astra"}:
            continue
        found.add(model["slug"])
        tiers = model.setdefault("service_tiers", [])
        if not any(tier.get("id") == "ultrafast" for tier in tiers):
            tiers.append({
                "id": "ultrafast",
                "name": "Ultrafast",
                "description": "Ultrafast API processing; premium API token pricing",
            })
        speeds = model.setdefault("additional_speed_tiers", [])
        if "ultrafast" not in speeds:
            speeds.append("ultrafast")
    if found != {"gpt-6.1-sol", "gpt-6-astra"}:
        raise ValueError("Expected demo models are missing from the CLI catalog")

    destination = Path(__file__).resolve().with_name("ultrafast-demo-models.json")
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=destination.parent, prefix=".catalog-", delete=False,
        ) as handle:
            temporary = Path(handle.name)
            json.dump(catalog, handle)
            handle.write("\n")
        os.replace(temporary, destination)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    print(destination)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        print("ultrafast-demo: could not prepare the model catalog; refusing to start with a potentially downgraded tier.", file=sys.stderr)
        sys.exit(1)
