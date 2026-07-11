# Testing Namida Sync

This document explains how to run, write, and extend tests for Namida Sync.

## Running Tests

- Run all tests:
  ```sh
  flutter test
  ```
- Run a specific test file:
  ```sh
  flutter test test/path/to/your_test.dart
  ```

## Test Types

- **Unit Tests:** Test business logic in isolation (e.g., services, models).
- **Widget Tests:** Test UI components and interactions.
- **Integration Tests:** For end-to-end flows.

## Writing New Tests

- Place unit/widget tests in the `test/` directory, mirroring the `lib/` structure.
- Use descriptive test names and group related tests.
- Mock dependencies for isolated testing.
- Use `setUp`/`tearDown` for test setup/cleanup.

## Best Practices

- Write tests for all new features and bug fixes.
- Keep tests small and focused.
- Use meaningful assertions and error messages.
- Run tests before submitting a pull request.

## References
- [Flutter Testing Docs](https://docs.flutter.dev/testing)
- [test package](https://pub.dev/packages/test) 