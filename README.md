# VOID Deploy Pipeline

CI/CD for VOID services. Runs on our **self-hosted Ubuntu runner** (label:
`self-hosted`). The `deploy` workflow checks out this repo and runs
`scripts/deploy.sh` on the runner.

> Contributors: branch, edit the deploy steps, and trigger the workflow from
> the Actions tab (`workflow_dispatch`). Builds run on the shared runner.
# trigger
