# DotMaster Branching Strategy

This document outlines the branching strategy for DotMaster development.

## Branch Structure

DotMaster uses a simplified Git workflow with two main branches:

### Main Branch

- **Branch name**: `main`
- **Purpose**: Contains the stable, production-ready version of the addon
- **Stability**: High - should always be functional for end users
- **When to use**: Final destination for completed features after testing

### Development Branch

- **Branch name**: `develop`
- **Purpose**: Active development work and integration of features
- **Stability**: Medium - may contain work-in-progress features
- **When to use**: Day-to-day development and feature integration

## Feature Development

For new features or significant changes:

1. Create a feature branch from `develop`
   ```
   git checkout -b feature/my-new-feature develop
   ```

2. Implement and test your changes in the feature branch

3. When feature is complete, merge back to `develop`
   ```
   git checkout develop
   git merge --no-ff feature/my-new-feature
   ```

4. After thorough testing in `develop`, merge to `main` for release
   ```
   git checkout main
   git merge --no-ff develop
   ```

## Hotfixes

For critical issues that need immediate fixes:

1. Create a hotfix branch from `main`
   ```
   git checkout -b hotfix/critical-issue main
   ```

2. Fix the issue in the hotfix branch

3. Merge back to both `main` and `develop`
   ```
   git checkout main
   git merge --no-ff hotfix/critical-issue
   git checkout develop
   git merge --no-ff hotfix/critical-issue
   ```

## Release Process

To release a new version:

1. Ensure all intended features are merged into `develop`
2. Test thoroughly in `develop`
3. Update version number in relevant files:
   - `DotMaster.toc`
   - `dm_core.lua` (the VERSION constant)
   - `Docs/CHANGELOG.md`
4. Merge `develop` into `main`
5. Tag the release in `main`:
   ```
   git tag -a v0.4.3 -m "Version 0.4.3"
   ```

## Important Notes

1. **No direct commits to main**: All changes to `main` should come through merges from `develop` or hotfix branches
2. **Keep branches in sync**: Regularly merge changes from `develop` back to feature branches to avoid conflicts
3. **Delete feature branches after merging**: Clean up merged feature branches to avoid confusion

## Common Mistakes to Avoid

- **Creating a release branch unnecessarily**: For this project size, a separate release branch is not needed - use `develop` for integration testing
- **Working directly in main**: Never work directly in the `main` branch - all development should happen in `develop` or feature branches
- **Merging untested code to main**: All code merged to `main` should be thoroughly tested in `develop` first

This simplified workflow provides adequate structure while minimizing overhead for the DotMaster project. 