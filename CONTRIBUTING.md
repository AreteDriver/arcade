# Contributing to Yokai Blade

Thank you for your interest in contributing to Yokai Blade!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Open the project in Unity 2022.3 LTS
4. Create a feature branch from `main`

## Development Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/YokaiBlade.git
cd YokaiBlade

# Open in Unity Hub
# Select Unity 2022.3.x LTS
```

## Code Standards

### C# Conventions
- **Naming**: PascalCase for public members, _camelCase for private fields
- **One class per file**
- **Use `[SerializeField]`** for inspector-exposed private fields
- **No hard-coded timings** — all timing in AttackDefinition ScriptableObjects

### Architecture
- **State machines** for boss AI
- **ScriptableObjects** for data-driven design
- **Fixed timestep** for combat logic (60 FPS baseline)

### Testing
- All boss behaviors must have unit tests
- Tests go in `Assets/Tests/EditMode/`
- Run tests via Unity Test Runner before submitting PR

## Invariants (Non-Negotiable)

Before contributing, read [INVARIANTS.md](docs/INVARIANTS.md). Key rules:

1. **Telegraph semantics never lie** — White flash = deflect, always
2. **No per-boss semantic overrides** — Global signals, global meaning
3. **Frame-rate independence** — Same timing at 30/60/120 FPS

## Pull Request Process

1. Ensure all tests pass
2. Update documentation if adding features
3. Follow commit message format:
   ```
   feat: Add new attack type
   fix: Correct deflect window timing
   docs: Update arena specification
   test: Add Oni phase transition tests
   ```
4. Request review from maintainers

## Issue Reporting

When reporting bugs:
- Include Unity version
- Describe expected vs actual behavior
- Provide steps to reproduce
- Include relevant logs/screenshots

## Project Structure

```
Assets/
  Core/           # Game systems (don't modify without tests)
  Game/           # Content (scenes, prefabs, assets)
  Tests/          # Unit and integration tests
docs/             # Design documentation
```

## Questions?

Open an issue with the `question` label or check existing documentation in `docs/`.
