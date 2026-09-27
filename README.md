# mac-tools

Small, self-contained tools that smooth out my day-to-day macOS workflow.
Each tool lives in its own folder under `tools/` and can be installed on
its own or all at once.

## Install

```sh
git clone https://github.com/nixsiow/mac-tools.git ~/Projects/mac-tools
cd ~/Projects/mac-tools
./install.sh          # everything
./install.sh -n       # dry run
./install.sh eject-all
```

`install.sh` symlinks each tool's `bin/*` into `~/bin` (so `git pull` updates
the live command) and, if Alfred is installed, packages any `alfred/` folder
into a `.alfredworkflow` and opens it for Alfred to import. It never
overwrites files in `~/bin` that it did not create.

Make sure `~/bin` is on your `PATH`:

```sh
export PATH="$HOME/bin:$PATH"
```

## Tools

| Tool | What it does |
|------|--------------|
| [eject-all](tools/eject-all/) | Safely eject every external disk in one go, stopping Time Machine first. Alfred keyword `eject`. |

## Layout

```
tools/<name>/
  bin/<name>      the command (bash, shellcheck-clean)
  alfred/         optional Alfred workflow source (info.plist etc.)
  README.md       what it does, why it exists, how to use it
```

## Requirements

- macOS (tested on macOS 26 "Tahoe", Apple silicon)
- [Alfred](https://www.alfredapp.com/) with Powerpack, only for the Alfred triggers

## License

MIT
