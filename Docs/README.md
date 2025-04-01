# DotMaster Documentation

Welcome to the DotMaster documentation repository. This folder contains all the documentation for the DotMaster addon project.

## ⚠️ Critical Development Notes

- [**CRITICAL API NOTES**](CRITICAL_API_NOTES.md) - Essential API requirements that MUST be followed (critically important)
- **Pre-Testing Verification** - Always check for potential errors and file structure inconsistencies before asking users to test in-game:
  - Verify TOC file references match actual files
  - Track file structure with every new version
  - Document file renames and maintain structure documentation
  - Verify initialization of renamed modules

## Documentation Structure

### Core Documents
- [Project Scope](PROJECT_SCOPE.md) - Overview of the project, core features, and technical requirements
- [Development Process](DEVELOPMENT_PROCESS.md) - Guidelines for development, versioning, and Git workflow
- [Current Status](CURRENT_STATUS.md) - Current development status, progress, and known issues
- [Changelog](CHANGELOG.md) - Comprehensive changelog of all versions
- [Missing Libraries](MISSING_LIBRARIES.md) - Instructions for installing required libraries
- [Code Structure](CODE_STRUCTURE.md) - Explanation of the modular code organization with prefix-based file structure
- [Current Files](CURRENT_FILES.md) - Current file structure tracked with each version update

### Patch Notes
Detailed patch notes for each released version:
- [v0.4.0 - Stable Restoration Release](PatchNotes/v0.4.0.md)
- [v0.3.0 - Complete Architectural Rebuild](PatchNotes/v0.3.0.md)
- [v0.1.1 - Initial Hotfix](PatchNotes/v0.1.1.md)

## For Developers

If you're new to the DotMaster development project, we recommend reading the documents in this order:

1. [**CRITICAL API NOTES**](CRITICAL_API_NOTES.md) - Read this FIRST - contains essential API requirements
2. [Project Scope](PROJECT_SCOPE.md) to understand what the addon does
3. [Current Status](CURRENT_STATUS.md) to see where we are in development
4. [Code Structure](CODE_STRUCTURE.md) to understand the modular organization
5. [Current Files](CURRENT_FILES.md) to understand the actual file structure
6. [Development Process](DEVELOPMENT_PROCESS.md) to learn how we work
7. [Changelog](CHANGELOG.md) to see the history of changes
8. [Missing Libraries](MISSING_LIBRARIES.md) if you need to set up the development environment

## Contributing

Please review the [Development Process](DEVELOPMENT_PROCESS.md) document before making any contributions to the project. It contains important information about our Git workflow, versioning policy, and coding standards.

## Branch Information

- **main**: Contains the latest stable release
- **develop**: Active development branch, always used for in-game testing

## Getting Help

If you have any questions about the project documentation or need clarification, please reach out to the project maintainer or open an issue on GitHub. 