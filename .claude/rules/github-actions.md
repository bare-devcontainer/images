---
description: GitHub Actions guidelines for the project.
paths:
  - ".github/workflows/*.yml"
  - ".github/workflows/*.yaml"
---

## GitHub Actions Guidelines

- Deny all permissions at the workflow level and only grant permissions that are necessary for each job.
- Set `timeout-minutes` on every job to prevent runaway builds from consuming resources.
- Every `uses:` reference must be pinned to a full commit SHA, with the version tag as a comment.
- Set `defaults.run.shell` to `bash -euo pipefail {0}` at the workflow level. The shell a step gets otherwise is `bash -e`, which leaves an unset variable empty and reports the status of the last command of a pipeline, so a failure anywhere before it goes unnoticed. A `run:` block therefore never sets those options for itself; a `runCmd:` or any other script the workflow hands to another program still has to.
- Always set `persist-credentials: false` on `actions/checkout` to prevent the GITHUB_TOKEN from being available to subsequent steps unintentionally:

For example:

```yaml
permissions: {}   # deny everything by default

jobs:
  build:
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha> # v6.0.3
        with:
          persist-credentials: false
```
