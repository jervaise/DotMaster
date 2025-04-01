# DotMaster Development Process

## Development Guidelines

### Local Development Environment

- **The local repository directory MUST always be on the `develop` branch**
  - This is critical as the local directory (`F:\World of Warcraft\_retail_\Interface\AddOns\DotMaster`) is directly loaded by WoW for in-game testing
  - After merging changes to `main` or other branches, always switch back to `develop` for continued development
  - GitHub Desktop should be configured to show the `develop` branch as the active branch
  - Any commits and changes will be continuously tested in-game from this directory

### Pre-Testing Verification

- **ALWAYS verify the following before asking users to test in-game:**
  - Check TOC file references match actual files in the directory
  - Verify all renamed files have been properly updated and old files removed
  - Check initialization code in core files to ensure all modules are properly initialized
  - Run a comprehensive error check for references to old/renamed files
  - Document all file structure changes in CURRENT_FILES.md
  - Update CODE_STRUCTURE.md when file organization changes

- **File Structure Management:**
  - After each version update, document the current file structure in CURRENT_FILES.md
  - When planning file renames, create a detailed rename plan document
  - Thoroughly check all file references after completing renames
  - Test module initialization for all renamed components

### Versioning Policy

- **ONLY create a new version when the addon is fully working without any known problems**
- Version numbers follow Semantic Versioning (MAJOR.MINOR.PATCH):
  - **MAJOR** version (X.0.0): Incompatible API changes
  - **MINOR** version (0.X.0): New functionality in a backward-compatible manner
  - **PATCH** version (0.0.X): Backward-compatible bug fixes

### Version Types

- **Release Versions**: Only created when the addon is completely stable and fully tested
- **Beta Versions**: May be created to save development progress when pausing work
  - Should be clearly marked as beta in commit messages and version notes
  - Not intended for distribution to end users
  - Created only upon explicit request from the project owner

### Git Workflow

- Regular changes should be committed and pushed to GitHub as needed
- All development should happen on the `develop` branch
- The `main` branch should only contain stable, working versions
- Versioning should be consistent across all files:
  - DotMaster.toc (## Version field)
  - DotMaster.lua (DotMaster.version property)
  - Any other relevant files

### Branching Strategy

We use a simplified GitFlow approach:

#### Core Branches

- **main** - Always contains the latest stable release
- **develop** - Integration branch for ongoing development
- **release-x.y.z** - Temporary branches for release preparation
- **hotfix-x.y.z** - Emergency fixes for the production version

#### Feature Development

1. **Create a feature branch** from `develop`:
   ```
   git checkout develop
   git checkout -b feature/feature-name
   ```

2. **Work on your feature** and commit changes regularly

3. **Merge back to develop** when complete:
   ```
   git checkout develop
   git merge --no-ff feature/feature-name
   git push origin develop
   ```

4. **Delete the feature branch** after successful merge

#### Release Process

1. **Create a release branch** from `develop` (only when addon is fully working):
   ```
   git checkout develop
   git checkout -b release-x.y.0
   ```

2. **Prepare the release**:
   - Update version numbers in all relevant files
   - Fix any last-minute bugs (commit to the release branch)
   - Update documentation and CHANGELOG.md
   - Create release notes

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

5. **Clean up**:
   ```
   git branch -d release-x.y.0
   ```

6. **Important**: Always return to the develop branch for continued development

#### Hotfix Process

1. **Create a hotfix branch** from `main`:
   ```
   git checkout main
   git checkout -b hotfix-x.y.z
   ```

2. **Implement the fix**:
   - Make necessary changes
   - Update version numbers in all files
   - Update CHANGELOG.md
   - Commit changes

3. **Merge to main and tag**:
   ```
   git checkout main
   git merge --no-ff hotfix-x.y.z
   git tag -a vx.y.z -m "Version x.y.z"
   git push origin main --tags
   ```

4. **Merge to develop**:
   ```
   git checkout develop
   git merge --no-ff hotfix-x.y.z
   git push origin develop
   ```

5. **Clean up**:
   ```
   git branch -d hotfix-x.y.z
   ```

### Version Restoration

- All versions must be properly tagged to allow easy restoration
- Previous versions should be easily accessible through Git history
- Critical points in development should have descriptive commit messages to aid in finding restore points

If a problem occurs, we can revert to a previous stable version:

1. **View available tags**:
   ```