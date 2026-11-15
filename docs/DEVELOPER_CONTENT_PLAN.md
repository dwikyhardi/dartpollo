# Developer documentation improvement plan

Status: approved and implemented locally; remote CI and publication have not been run. Created 2026-11-15 against commit `44f4a167e33f496ed2d9c1c405e3f49d1f510304`.

## Outcome and scope

A Dartpollo package user can install a documented release, generate typed GraphQL models, run a complete example, and apply the generated API in a real project. Guidance accurately describes the version it documents.

Primary audience: Dart and Flutter developers consuming the packages. Lead with a token-free Dart console example and generator-only usage. Keep the optional runtime and cache clearly explained. Preserve the existing useful configuration, transport, error and cache documentation.

This plan covers content, executable examples and checks that keep them accurate. It does not require a visual redesign, new runtime features, package publication or changes to generated API behavior. Flutter UI recipes, search and copy buttons remain later enhancements.

## 1. Correct release and behavior guidance — highest priority

- [x] Recheck pub.dev availability for the generator, annotations and runtime. The 2026-11-13 review found that the documented `^0.1.0-alpha.7` generator dependency did not resolve; do not assume that remains the publication state.
- [x] Use a verified published release for the default consumer journey. Confirm its API and generated output before changing dependency snippets. If these pages must describe unreleased behavior, label that scope explicitly and provide a complete checkout installation path separately.
- [x] Align dependency versions, SDK requirements, constructors and example links across the website, root/package READMEs and `PRODUCT.md`. Distinguish consumer SDK requirements from the workspace/CI SDK. Replace the obsolete `DartpolloClient(link: ...)` example with the appropriate supported constructor and fix root `example/` links.
- [x] Remove the claim that document optimization only changes representation. Document the verified inline-enum and directive problems for the affected version, alongside the existing generator-only import limitation. Recommend `optimize_document_nodes: false` for affected examples.
- [x] Explain absent, explicit-null and supplied variable values. Show the actual JSON for a nullable variable with a GraphQL default and the required Dart argument generated for a non-null variable with a default. Verify input-object defaults separately before making equivalent claims about them.
- [x] Document a tested omission technique for the applicable integration, including its limitations. Do not recommend indiscriminately removing nulls or editing generated code; intentional nulls have different semantics.

Main files: `docs/src/pages/getting-started.md`, `graphql-client.md`, `dartpollo-client.md`, `operations-and-variables.md`, `reference/generated-api.md`, `reference/generator-options.md`, `configuration.md`, `troubleshooting.md`, `index.astro`, plus READMEs and `PRODUCT.md`.

Acceptance: the default installation resolves in a clean package without workspace overrides; every version-specific warning matches the selected release; no remaining page claims optimization parity for the verified failing cases. Version numbers must describe actual releases or be clearly marked unreleased.

## 2. Deliver a complete first success

- [x] Create one small consumer fixture outside the Melos workspace membership, with its own dependency resolution. Start with the existing Viewer schema and query; avoid another application framework or documentation runner.
- [x] Include a complete `pubspec.yaml`, local SDL, operation, `build.yaml`, generated imports and a real `main()` using a fixed response map.
- [x] Walk through package creation, dependency installation, both builders and execution. Show the generated `.graphql.dart`/`.graphql.g.dart` paths and exact expected output.
- [x] Replace the undefined `responseData` snippet in Getting started with the runnable program. Explain that this first success validates generation and parsing; it does not make a network request.
- [x] Complete the next-step `package:graphql` example with `Future<void> main() async`, environment-token loading, client setup and error handling. Clearly distinguish standalone programs from excerpts that depend on earlier setup.
- [x] Keep the optional Dartpollo integration as a subsequent choice, with matching generated-helper configuration and lifecycle guidance.

Main files: `docs/src/pages/getting-started.md`, `graphql-client.md`, `integration-modes.md`, `dartpollo-client.md`; proposed fixture directory `docs/examples/developer-guide/`.

Acceptance: a developer can follow the quickstart from an empty directory and get the stated output without tokens, a live GraphQL endpoint or unpublished path overrides. Generation warnings and analyzer findings are reported accurately; successful execution alone is not called clean analysis.

## 3. Teach practical generated API usage

- [x] Add a complete mutation example: schema input, nested input construction, enum value, generated arguments and expected serialized variables. Demonstrate passing those variables through the existing client integration.
- [x] Extend the union/interface explanation from `__typename` dispatch to concrete Dart consumption. Reuse the GitHub example's `whereType<...Repository>()` pattern and show nullable list/item handling and useful field access.
- [x] Replace the custom-scalar placeholder with a small application-owned type and working encode/decode functions. Include the nullable/list converter shapes actually referenced by generated annotations.
- [x] Add an example of an unknown enum response and explain its difference from sending valid enum input values.
- [x] Add a small consumer test using local response JSON and generated parsers. For request behavior, demonstrate a fake/custom link where practical rather than requiring a public endpoint or credentials.
- [x] Reuse the consumer fixture for these examples so the documented type names, converter functions and JSON are compiled and checked.

Main files: `docs/src/pages/operations-and-variables.md`, `graphql-features.md`, `generated-output.md`, `guides/github.md`, `reference/generated-api.md`, and the consumer fixture.

Acceptance: no placeholder remains in an example presented as runnable. Tests verify nested input serialization, concrete union parsing, scalar round trips including null/list cases, and unknown enum response handling. Names shown in prose match generated symbols for the chosen configuration.

## 4. Explain project growth and maintenance

- [x] Add a realistic folder tree containing several operations and shared fragments, with the exact mappings, output files and Dart imports.
- [x] State explicitly that one schema mapping aggregates its matched documents into one generated library. One operation per source file does not automatically produce one library per file. Prefer explicit mappings for the demonstrated setup and show the actual wildcard limitation separately.
- [x] Describe schema acquisition, checked-in/local SDL ownership, regeneration after schema/operation/configuration changes, and how to inspect resulting changes. Retain the distinction between schema fetching and normal builds.
- [x] Add concise supported/limited behavior guidance with verified version boundaries, including optimization, variable defaults, scalar conversion and abstract types. Link existing runtime/cache caveats instead of duplicating them.
- [x] Link existing package changelogs and explain the prerelease upgrade workflow. Add migration instructions only for verified version differences; do not invent a stability guarantee.
- [x] Connect Getting started, API usage, project organization and troubleshooting with clear next-step links. Update navigation only if a new page is necessary.

Main files: `docs/src/pages/configuration.md`, `multiple-schemas.md`, `fragments.md`, `examples.md`, `troubleshooting.md`, and existing changelogs. Prefer extending these pages before creating new ones.

Acceptance: the documented multi-file setup generates exactly the stated libraries; every import resolves; a reader can locate schema update instructions and version-specific limitations without assembling them from unrelated pages.

## 5. Keep the documented journey working in CI

- [x] Add a docs build job to `.github/workflows/pull_request.yaml`, using the package manager and lockfile already used by `.github/workflows/docs.yml`.
- [x] Run the consumer fixture in isolation: resolve documented dependencies, generate both files, analyze, run the quickstart and execute the focused recipe checks.
- [x] Keep the published-release consumer check independent of workspace path overrides. If checking upcoming generator changes against the same fixture is useful, make that a separately named local-source check so it cannot mask a broken published installation.
- [x] Add a small check for local site links/anchors and generated recipe outputs where existing tooling allows it. Avoid building a general Markdown execution framework.
- [x] Resolve or explicitly account for any existing generated analyzer warnings. Fail on new errors and newly introduced warnings rather than hiding all generated diagnostics.
- [x] Document the local commands for reproducing the CI checks. Keep credentials and live endpoints out of required PR checks.

Acceptance: an invalid documented dependency, a broken example import/converter, an incorrect asserted result, or an Astro build failure causes a failing check. The published-release fixture runs without relying on the repository's package resolution.

## Delivery sequence and dependencies

1. **Accuracy and working onboarding:** phases 1–2 plus the minimal CI check for the initial fixture. Release/API alignment determines all later example content.
2. **Generated API recipes:** phase 3 with its focused checks added in the same change.
3. **Organization and maintenance:** phase 4, remaining CI/link checks from phase 5, and a final consistency pass over README, examples and website.

These are suggested reviewable change boundaries, not a requirement to create three pull requests. Every example ships with its verification rather than waiting for the final phase. For implementation branches, follow `feat/<task-id>-<short-task-description>` once a real task ID is available.

## Separate generator follow-ups

The content work must describe present behavior accurately. The following implementation work needs its own scope and compatibility tests:

- Optimized AST generation: preserve inline enum values and directives, and supply required imports for supported generation modes. Assert printed GraphQL semantics across the affected constructs before restoring a parity claim.
- Variable/input semantics: design any absent/null/value representation and GraphQL-default support deliberately, including nested inputs and serialization. Assess constructor/API compatibility before changing generated output.

Documentation improvements can ship while these limitations remain documented. If either fix ships first, reverify the behavior against its released version and revise the corresponding warnings and examples.

## Completion criteria

- A new package user installs, generates and runs the documented first example successfully.
- Practical recipes compile and their behavioral checks pass.
- Documentation claims match the release users actually install, including known limitations.
- README, website and examples agree on versions, paths, constructors and regeneration steps.
- Required docs checks run in PR CI, and the site builds successfully.
- The ai-memory review and repository knowledge are updated with completed work and remaining limitations, retaining the package-developer audience clarification.


## Implementation evidence — 2026-11-15

- Consumer docs and the standalone fixture now target the published `0.1.0-alpha.6` release. Pub.dev metadata and the downloaded package sources were checked; runtime, generator and annotation `lib/` sources match the reviewed checkout.
- The actual quickstart's five code blocks were installed and executed from a temporary directory: both generated files were produced, analysis passed and the program printed `octocat`. Both documented client alternatives were generated and analyzed in separate dependency resolutions.
- `graphql` 5.2.x and the Dartpollo alpha.6 runtime have incompatible `gql_dedupe_link` constraints. The docs now explain the choice; the published consumer fixture uses only `graphql`.
- Nine offline Dart consumer tests pass, covering nested inputs, null/default behavior, unions, scalar round trips, unknown enums, typed requests and errors. The fixture's analysis and formatting checks pass.
- Known generated `must_be_immutable` warnings are suppressed by generator configuration. The larger fixture also suppresses generated `unused_import` warnings from global scalar imports. No analyzer directory exclusion was added.
- Three validation-script tests pass. After `npm ci`, Astro builds all 20 pages and the built site's internal URLs, assets and anchors resolve.
- The PR workflow contains the docs build, link checks, isolated published quickstart/client checks, and recipe generation/analysis/format/tests. These commands were exercised locally with Dart 3.13.7; remote CI uses the existing repository SDK 3.12.1 and has not run for these uncommitted changes.
- Both checkout example dependency resolutions succeed with local annotation overrides, direct generated-source dependencies and updated locks. Pokémon generation was checked in a temporary package; no live GitHub or Pokémon endpoint was called.
- Project memory records these results and the still-open generator behavior limitations. Generator fixes remain separate follow-ups; this work changes documentation, example configuration and validation only.
