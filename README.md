# uptime-badge

> **Self-hosted shields.io-style uptime badge** for any URL. One bash script, no external services, no signup. Drop it in cron, the SVG updates itself.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/shell-bash-1f425f.svg)](#)
[![Output: SVG](https://img.shields.io/badge/output-SVG-orange.svg)](#)
[![Stars](https://img.shields.io/github/stars/fafsfafaf/uptime-badge?style=social)](https://github.com/fafsfafaf/uptime-badge/stargazers)

```bash
bash uptime-badge.sh https://example.com badge.svg --checks 10
```

## Demo

Recorded with [asciinema](https://asciinema.org/). View it locally:

```bash
# install asciinema if needed: pip install asciinema
asciinema play demo.cast
```

Or upload to asciinema.org for an embeddable badge:

```bash
asciinema auth      # one-time, opens browser
asciinema upload demo.cast
```

## Why

Shields.io has an "uptime" badge but it depends on third-party uptime services or paid integrations. If you already run a cron, you can generate the same SVG yourself in 30 lines of bash, host it next to your site, and own the data.

## Usage

```bash
# write SVG to stdout
bash uptime-badge.sh https://example.com

# write to a file
bash uptime-badge.sh https://example.com badge.svg

# control number of checks
bash uptime-badge.sh https://example.com badge.svg --checks 20
```

## Example output

The script renders the same color scheme as shields.io:

| Uptime | Color |
|--------|-------|
| ≥ 99%  | bright green |
| ≥ 95%  | green |
| ≥ 80%  | yellow |
| ≥ 50%  | orange |
| < 50%  | red |

Embed in markdown:

```markdown
![uptime](https://your-site.com/badge.svg)
```

## Run as cron (every 5 min)

```bash
# /etc/cron.d/uptime-badge
*/5 * * * *  www-data  /usr/local/bin/uptime-badge.sh \
    https://your-site.com /var/www/html/badge.svg --checks 5
```

Pair with nginx to serve `/var/www/html/badge.svg` at `https://your-site.com/badge.svg`. Done.

## Multi-URL setup

```bash
for site in api.mysite.com app.mysite.com www.mysite.com; do
    bash uptime-badge.sh "https://$site" "/var/www/badges/$site.svg" --checks 10
done
```

## How it works

- Runs `curl --max-time 6` against the URL N times in a row
- Counts 2xx/3xx as OK; everything else as down
- Reports % uptime and writes an SVG with shields.io-compatible coloring + sizing
- No persistent state — each run is independent. For historical uptime, run on a cron and append results to a log first.

## License

MIT
