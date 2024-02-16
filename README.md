# Get Azure DevOps Active Committers

This script will get the active committers from an Azure DevOps organization.

This is how it works:

<img src="images/demo.gif" />

## Pre-requisites

You need a Personal Access Token (PAT) with the following permissions:

- `Advanced Security (Read)`
- `Code (Read)`
- `Project and Team (Read)`

<img src="images/PAT scopes.png" />

## How to run it

The easiest way is to open this repo in GitHub Codespaces:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/0gis0/get-active-committers-for-ghazdo)

Or in a dev container in your local machine.

But if you don't want to use a Dev container, you can run the script in your local machine:

```bash
./active_commiters.sh
```

> **Note**: This will install gum in your local machine to make things pretty 🥰.
