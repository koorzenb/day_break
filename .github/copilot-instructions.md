# Copilot Instructions

Quick reference for GitHub Copilot and AI assistants working in this Flutter project.

**For specialized tasks, use the dedicated agent files in `.github/agent-*.md`**

---

## Essential Context

- **Project Config**: `.github/project-config.md` - project-specific settings
- **Product**: `PRD.md` - features, users, goals
- **Strategy**: `PLAN.md` - milestones, execution plan
- **Specialized Agents**:
  - `agent-review.md` - Code review and quality
  - `agent-planning.md` - Feature planning and TDD workflow
  - `agent-implementation.md` - Coding patterns and standards
  - `agent-testing.md` - Testing strategy and TDD

---

## Core Standards

### Platform & Tools

See `.github/project-config.md` for project-specific versions and requirements.

### Code Style (Quick Reference)

- Single quotes for strings (`'text'`)
- Arrow functions for callbacks (`() => action()`)
- Async/await (not `.then()`)
- Enums instead of string constants
- `///` docs for public APIs

### File Limits

- **UI files**: ≤200-250 lines (use `part`/`part of`)
- **Functions**: ≤30-50 lines (extract helpers)

### Testing

- **Mandatory**: All `expect` calls must have `reason` property
- **Location**: `test/` directory
- **Patterns**: Follow GetX, Hive patterns

---

## Security & Environment

```dart
// ❌ Never hardcode secrets
const apiKey = 'abc123';

// ✅ Use environment variables
final apiKey = dotenv.env['API_KEY'];
```

See `.github/project-config.md` for specific API keys and environment setup.

---

## Build Commands

```bash
flutter pub get          # Dependencies
flutter analyze          # Code analysis
flutter test            # Run tests
flutter build apk --debug  # Build
dart run update_version.dart  # Version bump for commits
```

---

## Quick Decision Guide

**Need detailed help with:**

- Code review → Use `agent-review.md`
- Feature planning → Use `agent-planning.md`
- Writing code → Use `agent-implementation.md`
- Writing tests → Use `agent-testing.md`

**Simple changes:** Follow standards above

---

**Copilot: For complex tasks, reference the specialized agent files. For simple work, follow the core standards above.**
