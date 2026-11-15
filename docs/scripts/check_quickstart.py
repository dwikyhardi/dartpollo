"""Execute the documented first-use path outside the Dart workspace."""

from pathlib import Path
import re
import subprocess
import tempfile

DOCS = Path(__file__).resolve().parents[1]
PAGES = DOCS / "src/pages"
FIXTURE = DOCS / "examples/developer-guide"
QUICKSTART_FILES = {
    "pubspec.yaml", "schema.graphql", "build.yaml",
    "lib/graphql/viewer.graphql", "lib/main.dart",
}


def file_blocks(page):
    return dict(re.findall(
        r'<span class="filename">([^<]+)</span>\s+'
        r'(?:<!--[^>]*-->\s+)?```(?:yaml|graphql|dart)\n(.*?)\n```',
        page, re.DOTALL,
    ))


def check_recipe_copies():
    count = 0
    for page in PAGES.rglob("*.md"):
        for name, code in re.findall(
            r'<!-- example: ([^ ]+) -->\s+```\w+\n(.*?)\n```',
            page.read_text(), re.DOTALL,
        ):
            expected = (FIXTURE / name).read_text().strip()
            if code.strip() != expected:
                raise ValueError(f"{page}: example differs from {name}")
            count += 1
    if count < 2:
        raise ValueError("Expected the scalar and GitHub recipe copies")


def run(package, *args):
    print("+ dart " + " ".join(args), flush=True)
    subprocess.run(["dart", *args], cwd=package, check=True)


def main():
    check_recipe_copies()
    files = file_blocks((PAGES / "getting-started.md").read_text())
    if set(files) != QUICKSTART_FILES:
        raise ValueError(f"Expected exactly the five quickstart files, got {set(files)}")
    if "dependency_overrides" in files["pubspec.yaml"]:
        raise ValueError("The published quickstart must not use dependency overrides")

    with tempfile.TemporaryDirectory(prefix="dartpollo-docs-") as directory:
        package = Path(directory)
        for name, code in files.items():
            target = package / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(code + "\n")
        run(package, "pub", "get")
        run(package, "run", "build_runner", "build")
        run(package, "analyze", "--fatal-infos")
        output = subprocess.check_output(
            ["dart", "run", "lib/main.dart"], cwd=package, text=True,
        ).strip()
        if output != "octocat":
            raise ValueError(f"Quickstart output: expected octocat, got {output!r}")
        print("Quickstart printed octocat", flush=True)

        # Compile each documented client alternative against the same Viewer input.
        # Separate resolutions are necessary: the two runtimes cannot coexist.
        header = files["pubspec.yaml"].split("\ndependencies:", 1)[0]
        for page_name, entry in [("graphql-client.md", "lib/github.dart"),
                                 ("dartpollo-client.md", "lib/main.dart")]:
            blocks = file_blocks((PAGES / page_name).read_text())
            (package / "pubspec.yaml").write_text(header + "\n" + blocks["pubspec.yaml"] + "\n")
            (package / "lib/github.dart").unlink(missing_ok=True)
            (package / entry).write_text(blocks[entry] + "\n")
            if page_name == "dartpollo-client.md":
                (package / "build.yaml").write_text(
                    files["build.yaml"].replace("generate_helpers: false", "generate_helpers: true") + "\n"
                )
            run(package, "pub", "get")
            run(package, "run", "build_runner", "build")
            run(package, "analyze", "--fatal-infos")
        print("Published quickstart and both client programs verified (no endpoint calls)")


if __name__ == "__main__":
    main()
