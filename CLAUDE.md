# AGENTS.md

Instructions for coding agents working on the Whispr infrastructure.

## Git/GitHub Standards

### Branch Naming Convention

All branches must follow this format:
```
WHISPR-<number>-<descriptive-name>
```

**Examples:**
- `WHISPR-123-add-user-authentication`
- `WHISPR-456-fix-payment-gateway`
- `WHISPR-789-update-api-documentation`

### Commit Message Format

Commits must follow a combination of **Gitmoji + Conventional Commit** format in English:

```
<gitmoji> <type>(<scope>): <description>

[optional body]

[optional footer]
```

**Rules:**
- Only ONE emoji at the beginning (the gitmoji)
- No other emojis anywhere in the commit message
- Write in English
- Keep the subject line under 72 characters
- Use imperative mood ("add" not "added" or "adds")

**Example:**
```
✨ feat(auth): add OAuth2 authentication flow

Implement Google and GitHub OAuth providers
Add token refresh mechanism

WHISPR-123
```

### Gitmoji Reference

Use these emojis for commits:

| Emoji | Code | Type | When to Use |
|-------|------|------|-------------|
| ✨ | `:sparkles:` | feat | Introduce new features |
| 🐛 | `:bug:` | fix | Fix a bug |
| 📝 | `:memo:` | docs | Add or update documentation |
| 🎨 | `:art:` | style | Improve structure/format of code |
| ♻️ | `:recycle:` | refactor | Refactor code |
| ⚡️ | `:zap:` | perf | Improve performance |
| ✅ | `:white_check_mark:` | test | Add or update tests |
| 🔧 | `:wrench:` | chore | Add or update configuration files |
| 🔨 | `:hammer:` | build | Add or update build scripts |
| 👷 | `:construction_worker:` | ci | Add or update CI configuration |
| 🚀 | `:rocket:` | deploy | Deploy stuff |
| 🔒️ | `:lock:` | security | Fix security issues |
| 🔥 | `:fire:` | remove | Remove code or files |
| 🚚 | `:truck:` | move | Move or rename files |
| 📦️ | `:package:` | deps | Add or update dependencies |
| ⬆️ | `:arrow_up:` | upgrade | Upgrade dependencies |
| ⬇️ | `:arrow_down:` | downgrade | Downgrade dependencies |
| 💄 | `:lipstick:` | ui | Add or update UI/styles |
| 🚧 | `:construction:` | wip | Work in progress |
| 🩹 | `:adhesive_bandage:` | hotfix | Simple fix for non-critical issue |
| 🔀 | `:twisted_rightwards_arrows:` | merge | Merge branches |
| ⏪️ | `:rewind:` | revert | Revert changes |

### Conventional Commit Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **build**: Changes to build system or dependencies
- **ci**: Changes to CI configuration
- **chore**: Other changes that don't modify src or test files

### Pull Request Title Format

PR titles must follow this format:
```
[WHISPR-<number>] <descriptive title>
```

**Rules:**
- NO emojis in PR titles
- Include Jira ticket number in brackets at the start
- Use clear, descriptive titles
- Write in English

**Examples:**
- `[WHISPR-123] Add user authentication system`
- `[WHISPR-456] Fix payment gateway timeout issue`
- `[WHISPR-789] Update API documentation for v2 endpoints`

### Quick Reference

**Branch:**
```
WHISPR-123-add-feature-name
```

**Commit:**
```
✨ feat(module): add new feature description
```

**Pull Request:**
```
[WHISPR-123] Add new feature description
```

## Infrastructure Development Principles

### Simplicity and Minimalism
- Always prefer the simplest and most direct solution
- Remove unnecessary elements: no example files, informational scripts, or redundant documentation
- Avoid premature abstractions

### Professional Approach
- No emojis in code, documentation, or scripts (except in commit messages as per Gitmoji standard)
- Clear and direct messages without embellishments
- Compliance with enterprise standards

### Separation of Responsibilities
- Administration scripts in `scripts/`
- Kubernetes manifests in `argocd/infrastructure/`
- GitOps configuration in `argocd/applications/`
- Terraform in `terraform/`

## Project Structure

```
infrastructure/
├── argocd/
│   ├── applications/          # ArgoCD applications (generic names)
│   ├── infrastructure/        # Kubernetes manifests by component
│   └── microservices/         # Microservices deployments
├── scripts/                   # Automation scripts only
├── terraform/                 # Infrastructure as Code
└── Justfile                   # Central task automation
```

## Development Conventions

### ArgoCD Applications
- Generic names (e.g., `rbac`, not `platform-engineers-rbac`)
- Appropriate sync waves: 1-10
- Auto-sync and self-healing enabled
- Source pointing to `argocd/infrastructure/`

### Shell Scripts
- Functional only, not informational
- Messages without emojis
- Permissions verified with `chmod +x`
- Clear environment variables

### Documentation
- Concise README (maximum 100 lines)
- No multiple READMEs per folder
- Direct instructions without excessive explanations
- No example files (.example)

### Justfile
- Commands organized by groups (`[group('name')]`)
- Clear and consistent task names
- No superfluous log messages
- Explicit dependencies between tasks

## Essential Commands

### Initial Setup
```bash
just setup-gcp-project <PROJECT_ID>    # GCP configuration
just setup-platform-access             # Team access (admin)
```

### Common Operations
```bash
just --list                             # See all commands
just verify-access                      # Test access (team)
just apply-app <app>                    # Deploy ArgoCD app
just clean                              # Clean temporary files
```

### Debugging
```bash
just get-pods-prod                      # Pods in production
just get-istio-authz                    # Istio policies
just cluster-info                       # Cluster info
```

## Strict Rules

### Do
- Keep generic and scalable structure
- Test changes with `just --list`
- Verify RBAC permissions after modifications
- Use appropriate ArgoCD sync waves

### Don't
- Example or demonstration files
- Scripts that only display information
- Detailed READMEs in each subfolder
- Emojis in any file except commit messages
- Team-specific ArgoCD applications

### Deployment
- Always via GitOps (ArgoCD)
- Modifications = Git push = Automatic deployment
- No manual `kubectl apply` in production
- Rollback via git revert

## Cluster Information

- **Name:** whispr-messenger
- **Zone:** europe-west1-b
- **Project:** whispr-messenger-472716
- **Prod namespace:** whispr-prod
- **Dev namespace:** platform-dev

## Security

- Team service account: `platform-engineers`
- Key rotation every 90 days
- Principle of least privilege
- Never commit credentials to git