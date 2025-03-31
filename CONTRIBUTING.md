# Contributing to DotMaster

Thank you for your interest in contributing to DotMaster! This document outlines our version control and branching strategy to ensure smooth development and the ability to revert to stable points at any time.

## Versioning Strategy

DotMaster follows [Semantic Versioning](https://semver.org/):

- **MAJOR version (X.0.0)** - For incompatible API changes or major redesigns
- **MINOR version (0.X.0)** - For new functionality added in a backward-compatible manner
- **PATCH version (0.0.X)** - For backward-compatible bug fixes

Version numbers are tracked in:
1. The tag system in Git
2. The `## Version:` field in `DotMaster.toc`
3. Release notes in GitHub

## Branching Strategy

We use a simplified GitFlow approach:

### Core Branches

- **main** - Always contains the latest stable release
- **develop** - Integration branch for upcoming features
- **release-x.y.z** - Temporary branches for release preparation
- **hotfix-x.y.z** - Emergency fixes for the production version

### Feature Development

1. **Create a feature branch** from `develop`:
   ```
   git checkout develop
   git checkout -b feature/feature-name
   ```

2. **Work on your feature** and commit changes

3. **Merge back to develop** when complete:
   ```
   git checkout develop
   git merge --no-ff feature/feature-name
   git push origin develop
   ```

4. **Delete the feature branch** after successful merge

### Release Process

1. **Create a release branch** from `develop`:
   ```
   git checkout develop
   git checkout -b release-x.y.0
   ```

2. **Prepare the release**:
   - Update version numbers in code
   - Fix any last-minute bugs (commit to the release branch)
   - Update documentation

3. **Merge to main and tag**:
   ```
   git checkout main
   git merge --no-ff release-x.y.0
   git tag -a vx.y.0 -m "Version x.y.0"
   git push origin main --tags
   ```

4. **Merge back to develop**:
   ```
   git checkout develop
   git merge --no-ff release-x.y.0
   git push origin develop
   ```

5. **Delete the release branch**:
   ```
   git branch -d release-x.y.0
   ```

### Hotfix Process

1. **Create a hotfix branch** from `main`:
   ```
   git checkout main
   git checkout -b hotfix-x.y.z
   ```

2. **Fix the issue** and commit changes

3. **Update version number** (patch increment)

4. **Merge to main and tag**:
   ```
   git checkout main
   git merge --no-ff hotfix-x.y.z
   git tag -a vx.y.z -m "Hotfix x.y.z"
   git push origin main --tags
   ```

5. **Merge to develop** to ensure the fix is in future releases:
   ```
   git checkout develop
   git merge --no-ff hotfix-x.y.z
   git push origin develop
   ```

6. **Delete the hotfix branch**:
   ```
   git branch -d hotfix-x.y.z
   ```

## Returning to a Stable Point

If you need to return to a previously stable point:

1. **View available tags**:
   ```
   git tag -l
   ```

2. **Create a branch from a specific tag**:
   ```
   git checkout -b recovery-branch v1.2.3
   ```

3. **Or reset current branch to a specific tag**:
   ```
   git reset --hard v1.2.3
   ```

## Code Style and Standards

- Use camelCase for variable and function names
- Keep functions small and focused on a single task
- Comment complex logic and document public API functions
- Follow Lua best practices for WoW addons

## Testing

- Test all changes in-game before submitting pull requests
- Verify compatibility with the current WoW patch
- Test across different character classes when relevant 