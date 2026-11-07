# Contributing to NEXORA

Thank you for contributing to NEXORA! We welcome code contributions, issue reports, documentation improvements, and security audits.

---

## Code of Conduct
Please review and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Development Workflow

1. **Fork and Branch**:
   - Create a feature branch from `main`:
     ```bash
     git checkout -b feature/your-feature-name
     ```
2. **Implement**:
   - Write clean, idiomatic Rust and Dart code.
   - Include unit tests for every new feature or bug fix.
   - Run linter and formatter:
     ```bash
     cargo fmt --all
     cargo clippy --workspace
     dart format .
     flutter analyze
     ```
3. **Commit**:
   - Use clear commit messages following Conventional Commits format (`feat:`, `fix:`, `docs:`, `test:`).
4. **Submit PR**:
   - Open a pull request against `main`. Ensure CI passes.
