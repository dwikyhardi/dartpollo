# Developer guide consumer fixture

[Documentation](https://dwikyhardi.github.io/dartpollo/) · [Getting started](https://dwikyhardi.github.io/dartpollo/getting-started/)

This independent Dart package verifies the website against published `dartpollo_generator` `0.1.0-alpha.6`. It is outside the root pub workspace and has no path dependencies or overrides. The runtime alternative is compiled separately because `graphql` 5.2.x and `dartpollo` alpha.6 require incompatible dedupe-link versions.

From this directory:

```sh
dart pub get
dart run build_runner build
dart analyze --fatal-infos
dart run lib/main.dart
dart test
```

`main.dart` prints `octocat`. Tests exercise nested input/enum serialization, absent/null/default behavior, union narrowing, unknown enum responses, scalar round trips, query errors and requests through fake links. They do not call live endpoints. `lib/github.dart` is a separately runnable live example requiring `GITHUB_TOKEN`.

`build.yaml` suppresses only the known generated `must_be_immutable` and `unused_import` warnings; the latter comes from global scalar imports. Application diagnostics and other generated diagnostics remain enabled. Generated files and local dependency locks are disposable; CI resolves the documented constraints from a clean package.

## Documentation checks

Run from the repository root:

```sh
python3 -m unittest discover -s docs/scripts
python3 docs/scripts/check_quickstart.py
npm --prefix docs ci
npm --prefix docs run build
npm --prefix docs run check:links
```

`check_quickstart.py` extracts the five named files from Getting started into a temporary directory, installs published dependencies, generates, analyzes and checks the printed output. It then compiles both documented client alternatives in separate dependency resolutions without calling their live endpoints. Tagged complete recipe blocks must match their checked-in source files. `check_links.py` checks local links, assets and fragments in built HTML.

PR CI runs these checks plus generation, analysis, formatting and tests for this fixture. CI uses the repository SDK (3.12.1); the consumer's declared minimum SDK is 3.10. Pub selects compatible transitive versions. For development against unpublished packages, use a separate local-source check; do not add overrides to this published-release fixture.


## Test local packages

For contributor testing, use a separate copy of the quickstart package alongside your Dartpollo checkout. Replace its generator dependency and override the annotation package:

```yaml
dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator:
    path: ../dartpollo/packages/dartpollo_generator
  json_serializable: ^6.11.0

dependency_overrides:
  dartpollo_annotation:
    path: ../dartpollo/packages/dartpollo_annotation
```

Keep the quickstart's regular dependencies and adjust paths for your checkout. The override resolves the annotation package locally when its version is not published yet.

For runtime helpers, add `dartpollo` as a regular path dependency to `../dartpollo/packages/dartpollo`, set `generate_helpers: true`, and leave optimization false. Use it separately from `graphql` 5.2.x because their link dependencies conflict.

Run `dart pub get`, regenerate, analyze and test. The root workspace requires Dart `^3.12.1`. Keep local overrides out of this published-release validation fixture.
