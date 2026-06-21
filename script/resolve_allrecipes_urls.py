#!/usr/bin/env python3
"""Resolve the exact Allrecipes recipe URL for each recipe by scraping the
Allrecipes search page with headless Chrome (curl/crawlers are bot-walled, a
real browser engine is not). Writes the result into recipes.canonical_url.

Runs against the dockerized app DB via `docker exec`. Resumable: only handles
recipes whose canonical_url is still NULL.

Usage: python3 script/resolve_allrecipes_urls.py [LIMIT] [WORKERS]
"""
import os, re, subprocess, sys, tempfile, time, urllib.parse, shutil
from concurrent.futures import ThreadPoolExecutor

CONTAINER = "recipe-app"
LIMIT = int(sys.argv[1]) if len(sys.argv) > 1 else 0          # 0 = all
WORKERS = int(sys.argv[2]) if len(sys.argv) > 2 else 2        # keep low: Allrecipes IP-bans bursts
DELAY = float(os.environ.get("RESOLVE_DELAY", "1.5"))        # polite pause between requests
CHROME = shutil.which("google-chrome") or shutil.which("chromium") or "google-chrome"
RECIPE_RE = re.compile(r'https://www\.allrecipes\.com/recipe/\d+/[a-z0-9-]+/?')
HREF_RE = re.compile(r'href="(https://www\.allrecipes\.com/recipe/\d+/[a-z0-9-]+/?)"')


def slugify(title):
    return re.sub(r'-+', '-', re.sub(r'[^a-z0-9]+', '-', title.lower())).strip('-')


def rails(script, stdin=None):
    return subprocess.run(
        ["docker", "exec", "-i", CONTAINER, "bash", "-lc",
         "cd /app && bundle exec rails runner -"],
        input=(stdin if stdin is not None else script), text=True,
        capture_output=True)


def fetch_recipe_url(title):
    q = urllib.parse.quote_plus(title)
    url = f"https://www.allrecipes.com/search?q={q}"
    profile = tempfile.mkdtemp(prefix="cr-")
    try:
        out = subprocess.run(
            [CHROME, "--headless=new", "--disable-gpu", "--no-sandbox",
             "--disable-dev-shm-usage", f"--user-data-dir={profile}",
             "--timeout=45000", "--virtual-time-budget=12000", "--dump-dom", url],
            capture_output=True, text=True, timeout=70).stdout
    except Exception:
        return None
    finally:
        shutil.rmtree(profile, ignore_errors=True)

    if "people.inc" in out or len(out) < 2000:
        return "BLOCKED"                              # IP-level access denial
    hrefs = HREF_RE.findall(out)
    if not hrefs:
        return None
    want = slugify(title)
    for h in hrefs:                                   # prefer exact title match
        if re.search(r'/recipe/\d+/' + re.escape(want) + r'/?$', h):
            return h
    return hrefs[0]                                   # else the top result


def main():
    limit_clause = f".limit({LIMIT})" if LIMIT else ""
    dump = rails(
        f'Recipe.where(canonical_url: nil).order(:id){limit_clause}'
        f'.pluck(:id, :title).each {{ |i, t| puts "#{{i}}\\t#{{t}}" }}')
    rows = [line.split("\t", 1) for line in dump.stdout.splitlines() if "\t" in line]
    total = len(rows)
    print(f"to resolve: {total} (workers={WORKERS})", flush=True)
    if not total:
        return

    resolved, done, blocked = {}, 0, 0

    def work(row):
        rid, title = row
        if DELAY:
            time.sleep(DELAY)
        return rid, fetch_recipe_url(title)

    def flush(batch):
        if not batch:
            return
        lines = [f'Recipe.where(id: {i}).update_all(canonical_url: {u!r})'
                 for i, u in batch.items()]
        rails(None, stdin="\n".join(lines))

    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        for rid, url in ex.map(work, rows):
            done += 1
            if url == "BLOCKED":
                blocked += 1
                if blocked >= 5:
                    print("ABORT: Allrecipes is IP-blocking this host "
                          "(People Inc access denial). Try a different network/proxy "
                          "or run later with WORKERS=1.", flush=True)
                    break
                continue
            blocked = 0
            if url:
                resolved[rid] = url
            if done % 25 == 0:
                print(f"{done}/{total} ({len(resolved)} found)", flush=True)
                flush(resolved); resolved = {}
    flush(resolved)
    print(f"done. resolved {len(resolved)} this flush; "
          f"total with url: run a count to confirm.", flush=True)


if __name__ == "__main__":
    main()
