from pathlib import Path
import tempfile
import unittest

from check_links import check_links
from check_quickstart import QUICKSTART_FILES, PAGES, check_recipe_copies, file_blocks


class DocumentationChecks(unittest.TestCase):
    def test_quickstart_files_and_copied_recipes(self):
        blocks = file_blocks((PAGES / "getting-started.md").read_text())
        self.assertEqual(set(blocks), QUICKSTART_FILES)
        self.assertIn("void main()", blocks["lib/main.dart"])
        check_recipe_copies()

    def test_links_resolve_relative_paths_assets_and_encoded_anchors(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "guide").mkdir()
            (root / "logo.svg").write_text("<svg/>")
            (root / "index.html").write_text(
                '<a href="guide/#a%20b">Guide</a><img src="/dartpollo/logo.svg">'
                '<a href="https://example.com/">External</a>'
            )
            (root / "guide/index.html").write_text(
                '<h2 id="a b">Title</h2><a href="../">Home</a>'
            )
            self.assertEqual(check_links(root), [])

    def test_missing_paths_anchors_and_incorrect_base_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "index.html").write_text(
                '<a href="missing/">Missing</a><a href="#absent">Anchor</a>'
                '<a href="/guide/">Wrong base</a>'
            )
            self.assertEqual(len(check_links(root)), 3)


if __name__ == "__main__":
    unittest.main()
