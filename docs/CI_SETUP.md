# CI/CD Setup Guide

## Required GitHub Secrets

### 1. GITHUB_TOKEN (automatic)
- **Purpose**: GitHub Releases, GHCR authentication
- **Scope**: Provided automatically by GitHub Actions

### 2. SNAPCRAFT_TOKEN (required for Snap publishing)
- **Purpose**: Publishing to Snap Store
- **How to get**:
  ```bash
  snapcraft export-login --snaps=quran-hadith --channels=stable -
  ```
- **Settings**: Repository → Secrets → Actions → New secret
- **Name**: `SNAPCRAFT_TOKEN`

### 3. FLATHUB_TOKEN (optional)
- **Purpose**: Creating PRs to Flathub repository
- **How to get**: GitHub Personal Access Token with `repo` scope
- **Settings**: Repository → Secrets → Actions → New secret
- **Name**: `FLATHUB_TOKEN`

## Workflow Permissions

Settings → Actions → General:
- ✅ Read and write permissions
- ✅ Allow GitHub Actions to create pull requests

## Triggering Builds

### Automatic (Release)
```bash
git tag v2.0.7
git push origin v2.0.7
```

### Manual
1. Go to Actions → Multi-Format Packaging
2. Click "Run workflow"
3. Enter version (e.g., `2.0.7`)
4. Click "Run workflow"

## First-Time Setup

1. **Snap Store**: First snap must be uploaded manually for review
2. **Flathub**: Submit initial app via Flathub submission process
3. **GHCR**: Automatic, no setup needed

## Monitoring

- Check Actions tab for build status
- Review artifacts before release
- Test packages on target distributions
