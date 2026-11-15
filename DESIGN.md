# Dartpollo Documentation Design

The logo is a faceted blue D with a light arrow entering its center: schema and operations become typed output. Use `docs/public/logo.svg` on dark surfaces; `docs/public/favicon.svg` adds a charcoal backing for browser tabs. Both use the same two-path mark, without gradients or fine detail. Keep the mark square and pair it with the existing Dartpollo wordmark in navigation.

The documentation follows the user-provided Islands Dark editor scheme, with brighter secondary labels and clearer surface separation: `#191A1C` canvas, `#232529` header and mobile navigation, `#2D3035` raised content and hover surfaces, `#CED0D6` text, `#9DA0A8` secondary text, and `#9498A1` subdued labels. Subdued labels meet WCAG AA for small text across these three surfaces. Separators use `#34363B`, with `#45484F` for stronger rules and outline rails. Blue (`#56A8F5` and `#83ACFC`) marks actions and selection; `#73BD79` marks success and `#C77DBB` secondary syntax. Platform sans is used for reading and platform monospace for code; there is no external font request.

The interface behaves like a developer reference pane, not a product landing page. A compact sticky header, grouped multi-page section index, 70-character reading measure, flat rules, and real code samples carry the hierarchy. The home page exposes the three generator boundaries—models, documents, and optional Dartpollo helpers—before installation.

Corners are 4–7px. Shadows, gradients, decorative diagrams, marketing metrics, alternating cards, and oversized calls to action are excluded. Mobile turns the section index into a horizontal sticky strip and keeps code locally scrollable.

Accessibility requirements: semantic landmarks, keyboard-visible focus, a skip link, WCAG AA text contrast, 44px navigation targets, reduced-motion support, and no meaning communicated by color alone.
