(() => {
    const container = document.getElementById("readme");
    if (!container) return;

    const renderError = (err) => {
        container.innerHTML = "<h1>Omarchy Mac</h1><p>Could not render README.md.</p><pre></pre>";
        const pre = container.querySelector("pre");
        if (pre) pre.textContent = String(err);
    };

    const githubSlug = (value) =>
        value
            .trim()
            .toLowerCase()
            .normalize("NFKD")
            // Normalize common dash characters to ASCII hyphen.
            .replace(/[\u2010-\u2015\u2212\uFE58\uFE63\uFF0D]/g, "-")
            // Drop diacritics.
            .replace(/[\u0300-\u036f]/g, "")
            // Keep alnum, spaces, and hyphens (do not collapse spaces).
            .replace(/[^a-z0-9 -]/g, "")
            .replace(/ /g, "-");

    (async () => {
        try {
            if (!window.marked?.parse) {
                throw new Error("Missing markdown renderer (marked.parse is not available).");
            }

            const res = await fetch("README.md");
            if (!res.ok) throw new Error(`fetch README.md failed (${res.status})`);
            const markdown = await res.text();

            // Keep GFM behavior but avoid e-mail mangling.
            container.innerHTML = window.marked.parse(markdown, { gfm: true, mangle: false });

            // Add GitHub-ish heading IDs so the README TOC links work.
            const slugCounts = new Map();
            for (const heading of container.querySelectorAll("h1,h2,h3,h4,h5,h6")) {
                if (heading.id) continue;
                const base = githubSlug(heading.textContent || "");
                if (!base) continue;
                const n = slugCounts.get(base) || 0;
                slugCounts.set(base, n + 1);
                heading.id = n === 0 ? base : `${base}-${n}`;
            }

            // Open external links in a new tab.
            for (const a of container.querySelectorAll("a[href]")) {
                const href = a.getAttribute("href") || "";
                if (/^https?:\/\//i.test(href)) {
                    a.target = "_blank";
                    a.rel = "noreferrer noopener";
                }
            }

            // If the page is opened with a hash, jump after we inject IDs.
            if (location.hash.length > 1) {
                const target = document.getElementById(decodeURIComponent(location.hash.slice(1)));
                if (target) target.scrollIntoView();
            }
        } catch (err) {
            renderError(err);
        }
    })();
})();

