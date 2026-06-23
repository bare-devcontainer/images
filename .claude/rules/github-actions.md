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
