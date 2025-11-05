# Clang Static Analyzer (scan-build) for gRPC

This directory contains the infrastructure for running Clang Static Analyzer on the gRPC codebase.

## Overview

The Clang Static Analyzer is a source code analysis tool that finds bugs in C, C++, and Objective-C programs. It performs path-sensitive, inter-procedural analysis to find bugs that compilers miss.

This setup follows the same pattern as clang-tidy:
1. Generate a compilation database using Bazel
2. Run scan-build in a Docker container for consistency
3. Generate analysis reports in multiple formats

## Usage

### Running Locally

To run scan-build on the entire codebase:

```bash
tools/distrib/scan_build_code.sh
```

Reports will be generated in `scan-build-reports/` directory in the repository root.

### Viewing Reports

Scan-build generates reports in two formats:

**HTML Reports (for humans):**
```bash
scan-view scan-build-reports/<timestamp-directory>
```

Or manually open the `index.html` files in the report directories.

**SARIF Reports (for tools):**
SARIF files can be imported into IDEs and other analysis tools:
- VS Code: Use extensions that support SARIF
- GitHub: Can be uploaded to Code Scanning
- Other tools: Many static analysis tools support SARIF format

### Output Formats

By default, both formats are generated:
- **HTML**: Human-readable reports with source code highlighting
- **SARIF**: Machine-readable JSON format for tool integration

### Customization

You can customize the analysis by setting environment variables:

**Change output directory:**
```bash
SCAN_BUILD_OUTPUT=/tmp/my-reports tools/distrib/scan_build_code.sh
```

**Skip Docker (run locally):**
```bash
SCAN_BUILD_SKIP_DOCKER=1 tools/distrib/scan_build_code.sh
```

## How It Works

1. `scan_build_code.sh` generates a compilation database using Bazel
2. The script builds the Docker image from this directory
3. Docker runs `scan_build_all_the_things.sh` which:
   - Filters relevant source files from the compilation database
   - Runs scan-build on those files
   - Generates reports in both HTML and SARIF formats
4. Reports are saved to the output directory

## Analyzed Files

The analysis covers:
- `include/` - Public headers
- `src/core/` - Core implementation
- `src/cpp/` - C++ implementation
- `test/core/` - Core tests
- `test/cpp/` - C++ tests

Excluded:
- Generated files (upb-gen, upbdefs-gen)
- Telemetry stats data
- Port definition files

## Differences from clang-tidy

- **Analysis depth**: scan-build performs deeper control flow and data flow analysis
- **Output format**: Generates report files instead of inline messages
- **Auto-fix**: No auto-fix capability (scan-build finds issues, doesn't fix them)
- **Use case**: Better for finding complex bugs like memory leaks, null dereferences, use-after-free

## Checkers

By default, scan-build runs with a comprehensive set of checkers including:

- **Core checkers**: Null dereferences, undefined behavior, divide-by-zero
- **Memory checkers**: Leaks, use-after-free, double-free
- **Dead code**: Unreachable code, unused variables
- **Security**: Buffer overflows, insecure API usage
- **C++ specific**: Iterator invalidation, move semantics issues

The full list of checkers can be viewed with:
```bash
clang --analyze -Xanalyzer -analyzer-checker-help
```

## CI Integration

The scan-build analysis is also run in CI on pull requests. See `.github/workflows/scan-build.yaml` for the CI configuration.

## Troubleshooting

**Docker build fails:**
- Ensure Docker is running
- Try: `docker system prune` to clean up old images

**Analysis takes too long:**
- scan-build is slower than clang-tidy due to deeper analysis
- Consider analyzing a subset of files during development

**No reports generated:**
- This might mean no issues were found (good!)
- Check the console output for any errors
- Use `--keep-empty` to keep empty report directories

## Resources

- [Clang Static Analyzer Documentation](https://clang.llvm.org/docs/ClangStaticAnalyzer.html)
- [scan-build Manual](https://clang-analyzer.llvm.org/scan-build.html)
- [SARIF Format Specification](https://sarifweb.azurewebsites.net/)
