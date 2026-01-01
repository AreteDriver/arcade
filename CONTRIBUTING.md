# Contributing to EVE Rebellion

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in [GitHub Issues](https://github.com/AreteDriver/eve_rebellion_rust/issues)
2. If not, create a new issue with:
   - Clear description of the problem or suggestion
   - Steps to reproduce (for bugs)
   - Your OS and Rust version
   - Any relevant error messages or screenshots

### Submitting Changes

1. **Fork and clone**
   ```bash
   git clone https://github.com/AreteDriver/eve_rebellion_rust.git
   cd eve_rebellion_rust
   ```

2. **Build and run**
   ```bash
   cargo build
   cargo run
   ```

3. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed

5. **Run tests and linting**
   ```bash
   cargo test
   cargo fmt
   cargo clippy
   ```

6. **Commit and push**
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**

## Code Style

- Run `cargo fmt` before committing
- Run `cargo clippy` and fix warnings
- Use meaningful variable and function names
- Add documentation comments for public items
- Avoid `unwrap()` in production code - use proper error handling

## Testing

- Write tests for new functionality
- Ensure all existing tests pass
- Run tests with: `cargo test`

## Project Structure

```
eve_rebellion_rust/
├── src/
│   ├── main.rs         # Entry point and game loop
│   ├── player.rs       # Player ship and controls
│   ├── enemies.rs      # Enemy types and AI
│   ├── weapons.rs      # Weapons and projectiles
│   ├── powerups.rs     # Power-up system
│   ├── audio.rs        # Sound effects
│   └── sprites.rs      # Sprite loading and rendering
├── assets/             # Game assets (sprites, sounds)
├── web/                # WASM web build files
└── Cargo.toml          # Dependencies
```

## Building for Web (WASM)

```bash
./build-wasm.sh
cd web && python3 -m http.server 8080
```

## Areas for Contribution

### High Priority
- New enemy types
- Boss battles
- Additional power-ups
- Sound effects and music

### Medium Priority
- High score persistence
- Difficulty settings
- Mobile touch controls
- Gamepad support

### Nice to Have
- Multiplayer support
- Level editor
- More ship variants
- Achievements

## Development Tips

### Adding a new enemy
1. Define the enemy struct in `src/enemies.rs`
2. Implement spawn and behavior logic
3. Add sprite loading in `src/sprites.rs`
4. Test spawn patterns

### Adding a power-up
1. Define in `src/powerups.rs`
2. Implement collection logic
3. Add visual effects
4. Balance gameplay impact

## Questions?

- Open an issue for questions
- Check existing issues and discussions

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

Thank you for contributing!
