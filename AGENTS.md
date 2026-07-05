# AGENTS.md — DRC BDBV Interactive Map 

Orientation for AI agents (and humans) working in this repo. Read this first, then the
files under [`.agents/`](.agents/) for depth.

## What this project does

Creates a near live, granular map of DRC BDBV cases in the 2026 outbreak, including nowcast and forecast models

## Stack & entry points

- **Language**: R (>= 4.6). **Orchestration**: [`targets`](https://docs.ropensci.org/targets/)
  + `tarchetypes`, with a `crew` local controller (parallel workers = env `NPROC`, else 8).
- **Storage**: content-addressable (CAS) local store at [`_targets.R`](_targets.R)).
- **Pipeline definition**: [`_targets.R`](_targets.R) sources every `_targets_*.R` and every
  `R/*.R`, then calls `all_targets()` ([`R/all_targets.R`](R/all_targets.R)) to collect all
  target objects. The main pipeline is in [`_targets_bdbv.R`](_targets_bdbv.R), written
  with the `tar_assign({ x <- f(y) |> tar_target() })` DSL.
- **Functions**: one function per file under [`R/`](R/), roxygen-style header comments.

## Running

```sh
# Full pipeline
Rscript -e 'targets::tar_make()'
# Inspect a target
Rscript -e 'targets::tar_read(nsf_pi_roster)'
# Visualize the DAG
Rscript -e 'targets::tar_manifest(fields = c("name","pattern"))'
```

## Conventions you MUST follow

- **Update documentation** every time a major step is passed, decision made, or data schema discovered.
Update AGENTS.md and appropriate .agents/*.md files so a new session/agent may pick up where left off.
- **New targets** go in `_targets_*.R` files using the pipe DSL: `name <- fn(deps) |> tar_target()`.
  `targets`/`tarchetypes` are attached and `R/*.R` sourced, so do **not** namespace those or
  the project's own functions. Do namespace non-attached pkgs (`airtable2::`, `s3fs::`,
  `nanoparquet::`, `duckdb::`, `DBI::`).
- **Style**: tidyverse; 2-space indent; snake_case; roxygen `#'` headers with `@author`.

## Where Agents should put documentation

- [`.agents/architecture.md`](.agents/architecture.md) — the full pipeline, layer by layer.
- [`.agents/decisions.md`](.agents/decisions.md) — why the design is what it is.
- [`.agents/plan.md`](.agents/plan.md) — the detailed, step-by-step build plan (per-function
  specs + verification), written so any agent can execute a single step.
- [`.agents/todo.md`](.agents/todo.md) — current status / what's left.
