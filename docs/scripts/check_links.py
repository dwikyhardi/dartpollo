"""Check local URLs and fragments in Astro's built site without a server."""

from html.parser import HTMLParser
from pathlib import Path
import sys
from urllib.parse import unquote, urljoin, urlsplit


class Page(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.ids = set()
        self.urls = []
        self.feed(html)

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        for key in ("href", "src"):
            if key in attrs:
                self.urls.append(attrs[key])


def check_links(root):
    pages = {path: Page(path.read_text()) for path in root.rglob("*.html")}
    errors = []
    if not pages:
        return [f"No built HTML in {root}; run npm run build first"]
    for path, page in pages.items():
        relative = path.relative_to(root).as_posix()
        url = "/dartpollo/" + relative.removesuffix("index.html")
        for href in page.urls:
            target = urlsplit(urljoin(url, href))
            if target.scheme or target.netloc:
                continue
            if not target.path.startswith("/dartpollo/"):
                errors.append(f"{relative}: URL leaves site base: {href}")
                continue
            destination = root / unquote(target.path.removeprefix("/dartpollo/"))
            if destination.is_dir():
                destination /= "index.html"
            if not destination.is_file():
                errors.append(f"{relative}: missing target: {href}")
            elif target.fragment and destination in pages:
                if unquote(target.fragment) not in pages[destination].ids:
                    errors.append(f"{relative}: missing anchor: {href}")
    return errors


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1] / "dist"
    errors = check_links(root)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)
    print("Built site: local links, assets and anchors resolve")
