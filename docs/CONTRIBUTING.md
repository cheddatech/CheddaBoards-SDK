# Contributing to CheddaBoards

Thank you for your interest in contributing to CheddaBoards! We welcome contributions from the community and are grateful for any help you can provide.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please treat all participants with respect and help us create a welcoming environment for everyone.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Your environment (browser, OS, CheddaBoards version)
- Code snippets or error messages
- Screenshots if applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- A clear and descriptive title
- Detailed description of the proposed functionality
- Use cases and examples
- Why this enhancement would be useful
- Possible implementation approach (if you have ideas)

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding standards** (see below)
3. **Write tests** for new functionality
4. **Update documentation** as needed
5. **Ensure all tests pass**
6. **Submit a pull request** with a clear description

## Development Setup

### Prerequisites

- Node.js 16+ and npm
- dfx (DFINITY SDK) for local canister development
- Git

### Local Development

```bash
# Clone your fork
git clone https://github.com/your-username/cheddaboards.git
cd cheddaboards

# Install dependencies
npm install

# Start local ICP replica
dfx start --clean

# Deploy canister locally
dfx deploy

# Run tests
npm test

# Build SDK
npm run build
```

### Project Structure

```
cheddaboards/
├── src/
│   ├── sdk/              # JavaScript SDK source
│   │   ├── core/         # Core functionality
│   │   ├── auth/         # Authentication modules
│   │   └── utils/        # Utilities
│   └── backend/          # Motoko canister source
├── tests/                # Test files
├── examples/             # Example implementations
└── docs/                 # Documentation
```

## Coding Standards

### JavaScript/TypeScript

- Use ES6+ features
- Follow existing code style (2 spaces, no semicolons optional)
- Use meaningful variable names
- Add JSDoc comments for public APIs
- Keep functions small and focused

```javascript
/**
 * Submits a score to the leaderboard
 * @param {number} score - Player's score (max 15000)
 * @param {number} streak - Player's streak (max 600)
 * @returns {Promise<Result>} Submission result
 */
async function submitScore(score, streak) {
  // Implementation
}
```

### Motoko

- Follow official Motoko style guide
- Use clear type definitions
- Document public functions
- Handle errors explicitly
- Keep actor methods focused

```motoko
/// Submit a score for a game
/// Returns #ok("message") or #err("error")
public shared(msg) func submitScore(
  userIdType : Text,
  userId : Text,
  gameId : Text,
  scoreNat : Nat,
  streakNat : Nat
) : async Result.Result<Text, Text> {
  // Implementation
}
```

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- auth.test.js

# Run with coverage
npm run test:coverage
```

### Writing Tests

- Write tests for all new functionality
- Follow the existing test structure
- Use descriptive test names
- Test both success and failure cases
- Mock external dependencies

```javascript
describe('submitScore', () => {
  it('should submit valid score successfully', async () => {
    const result = await chedda.submitScore(100, 5);
    expect(result.success).toBe(true);
  });

  it('should reject score exceeding maximum', async () => {
    const result = await chedda.submitScore(20000, 5);
    expect(result.success).toBe(false);
    expect(result.error).toContain('exceeds maximum');
  });
});
```

## Documentation

- Update README.md for user-facing changes
- Update API documentation for new methods
- Add JSDoc comments to all public functions
- Include code examples where helpful
- Keep documentation concise and clear

## Commit Messages

Follow conventional commits format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build process or auxiliary tool changes

Examples:
```
feat(auth): add Apple Sign-In support

Implemented Apple authentication flow with JWT validation.
Includes session management and error handling.

Closes #123
```

## Review Process

1. **Automated checks** run on all PRs (tests, linting)
2. **Code review** by at least one maintainer
3. **Discussion** and requested changes if needed
4. **Approval** and merge when ready

## Release Process

1. Update version in package.json
2. Update CHANGELOG.md
3. Create release PR
4. After merge, tag release
5. Publish to npm
6. Create GitHub release

## Getting Help

- **Discord**: Join our community for discussions
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: Check our docs first
- **Examples**: Review example implementations

## Recognition

Contributors will be recognized in:
- The CONTRIBUTORS.md file
- Release notes for significant contributions
- Our documentation site

## Questions?

Feel free to ask questions in:
- GitHub Discussions
- Discord community
- Issue comments

We appreciate your contributions and look forward to working with you!
