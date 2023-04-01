# Action Runners

This repository holds personalized Docker images that can be utilized as action runners, such as in GitHub Action Workflows, for future purposes.

## Available Runners

| Build status                                                                                                                                                                             | Description                            | Image                                                                                            | Latest Version                                                                                   |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|--------------------------------------------------------------------------------------------------| --- |
| [![build: gitops](https://github.com/maandr/action-runners/actions/workflows/build-gitops.yaml/badge.svg)](https://github.com/maandr/action-runners/actions/workflows/build-gitops.yaml) | A runner designed for GitOps projects. | [repository](https://github.com/users/maandr/packages/container/package/action-runners%2Fgitops) | `1.0.0`|

## Usage in GitHub Actions

In order to utilize an action runner from this compilation, you need to specify it in the [`container`](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idcontainer) field of the job. Please ensure that the secret `CONTAINER_REGISTRY_PAT` is accessible within the repository, as it is necessary for authenticating with the container registry.

```yaml
jobs:
  myjob:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/maandr/action-runners/gitops:1.0.0
      credentials:
        username: ${{ github.repository_owner }}
        password: ${{ secrets.CONTAINER_REGISTRY_PAT }}
```
