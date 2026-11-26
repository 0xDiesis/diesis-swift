"""Validate the pinned contracts and generator used by generate.py."""

from __future__ import annotations

import hashlib
import json
import os
import platform
import subprocess
import tempfile
from pathlib import Path

PROVENANCE = Path(__file__).resolve().parents[1] / "contracts-provenance.json"


def canonical_json(value) -> bytes:
    return json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode("utf-8")


def normalized_abi(abi: list[dict]) -> bytes:
    # Match the normalization used in the umbrella contracts manifest.
    for entry in abi:
        if entry.get("outputs") == []:
            del entry["outputs"]
        if entry.get("type") in ("receive", "fallback") and entry.get("inputs") == []:
            del entry["inputs"]
    return canonical_json(sorted(abi, key=canonical_json))


def verified_generator(contracts: Path, pin: dict) -> Path:
    system = platform.system()
    machine = platform.machine().lower()
    architecture = {
        "arm64": "aarch64", "aarch64": "aarch64", "amd64": "x86_64", "x86_64": "x86_64",
    }.get(machine, machine)
    system_target = {"Darwin": "apple-darwin", "Linux": "unknown-linux-gnu", "Windows": "pc-windows-msvc"}
    target = f"{architecture}-{system_target.get(system, system)}"
    expected_hash = pin["binarySha256"].get(target)
    if expected_hash is None:
        raise SystemExit(f"no pinned abi-typegen binary for {target}")
    name = "abi-typegen.exe" if system == "Windows" else "abi-typegen"
    installed = contracts / "node_modules/@0xdoublesharp/abi-typegen/bin" / name
    binary = Path(os.environ.get("ABI_TYPEGEN") or installed).resolve()
    if not binary.is_file():
        raise SystemExit(f"abi-typegen not found at {binary}; set ABI_TYPEGEN to the release executable")
    if hashlib.sha256(binary.read_bytes()).hexdigest() != expected_hash:
        raise SystemExit(f"{binary}: SHA-256 mismatch for {pin['version']} ({target})")
    return binary


def stage_artifacts(contracts: Path, names: list[str], destination: Path, pin: dict) -> None:
    artifacts = Path(os.environ.get("DIESIS_ARTIFACTS_DIR") or contracts / "out")
    entries = {entry["name"]: entry for entry in pin["contracts"]}
    if len(entries) != len(pin["contracts"]) or entries.keys() != set(names):
        raise SystemExit("selected contracts and pinned ABI list differ")
    for name in names:
        entry = entries[name]
        relative = Path(Path(entry["source"]).name) / f"{name}.json"
        path = artifacts / relative
        if not path.is_file():
            raise SystemExit(f"missing compiled contract artifact {path}")
        content = path.read_bytes()
        artifact = json.loads(content)
        metadata = artifact["metadata"]
        if metadata["compiler"]["version"] != pin["compilerVersion"]:
            raise SystemExit(f"{path}: compiler version mismatch")
        if metadata["settings"]["compilationTarget"] != {entry["source"]: name}:
            raise SystemExit(f"{path}: compilation target mismatch")
        digest = hashlib.sha256(normalized_abi(artifact["abi"])).hexdigest()
        if digest != entry["abiSha256"]:
            raise SystemExit(f"{path}: normalized ABI SHA-256 mismatch")
        staged = destination / relative
        staged.parent.mkdir(parents=True, exist_ok=True)
        staged.write_bytes(content)


def generate(
    contracts: Path, names: list[str], target: str, out: Path, package: str | None = None
) -> None:
    pin = json.loads(PROVENANCE.read_text(encoding="utf-8"))
    revision = subprocess.check_output(
        ["git", "-C", str(contracts), "rev-parse", "HEAD"], text=True
    ).strip()
    if revision != pin["contractsRevision"]:
        raise SystemExit(f"{contracts}: expected contracts HEAD {pin['contractsRevision']}, found {revision}")
    if subprocess.run(["git", "-C", str(contracts), "diff", "--quiet", "HEAD"]).returncode != 0:
        raise SystemExit(f"{contracts}: tracked contracts files differ from HEAD")
    binary = verified_generator(contracts, pin["generator"])
    with tempfile.TemporaryDirectory(prefix="diesis-verified-artifacts-") as temp:
        artifacts = Path(temp)
        stage_artifacts(contracts, names, artifacts, pin)
        command = [
            str(binary), "generate", "--artifacts", str(artifacts), "--out", str(out),
            "--target", target, "--contracts", ",".join(names),
        ]
        if package is not None:
            command.extend(["--package", package])
        subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
