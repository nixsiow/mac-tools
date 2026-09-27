# eject-all

Safely eject every external physical disk attached to the Mac, in one command.
Built for the "unplug the dock at the end of the day" routine.

## Why

Yanking a Thunderbolt dock with drives attached unmounts them uncleanly. Do
that daily and sooner or later a write is in flight when the cable comes out.
In my case it was a Time Machine backup: months of hourly backups plus daily
hard-disconnects ended in an APFS container whose space manager `fsck_apfs`
could not repair, and an encrypted volume whose keybag could no longer be
read. The only fix was to erase the drive and start over.

Ejecting three drives by hand every evening is tedious enough that it does not
happen. One keyword in Alfred does.

## What it does

1. Finds every whole disk macOS classifies as **external and physical**
   (USB / Thunderbolt, including drives behind a dock). Each candidate is
   re-verified independently: it must be a whole disk, external, not virtual,
   and not the disk the system is running from. Disk images, network shares
   and the internal SSD are never touched.
2. If a **Time Machine** backup is running, asks it to stop and waits for it
   to finish cleanly (default 90 s). If it will not stop, **nothing is
   ejected** and you are told not to unplug.
3. Ejects each disk with `diskutil eject` (whole-disk, so multi-volume drives
   and APFS containers go in one step). **Never forces.** Retries a few times
   to ride out short-lived holders such as Spotlight.
4. Reports the result. From a terminal: on stdout. From Alfred or anything
   without a TTY: as a macOS notification, either **"Safe to unplug"** or
   **"Do NOT unplug yet"** with the names of the processes holding the disk.

## Usage

```
eject-all                # eject everything
eject-all -n             # dry run: show what would be ejected
eject-all -t 180         # wait up to 180 s for Time Machine
eject-all -v             # show diskutil / tmutil output
eject-all --notify       # force a notification even from a terminal
eject-all --help
```

Alfred: type `eject`, press Enter, wait for the notification, pull the cable.

Exit codes: `0` all ejected (or nothing attached), `1` something could not be
ejected, `2` Time Machine did not stop (nothing ejected), `64` bad usage,
`75` another instance is already running.

Log of real actions: `~/Library/Logs/eject-all.log`.

## Safety notes

- Fixed `PATH`, `set -euo pipefail`, no `eval`, shellcheck-clean.
- Disk identifiers are validated against `^disk[0-9]+$` before any command
  sees them.
- Notification text is passed to AppleScript as arguments, so a volume or
  process name can never be interpreted as code.
- A lock prevents two runs at once (e.g. a double-tap in Alfred).
- Discovery merges two sources, `diskutil list external physical` and the
  physical disk behind every mounted `/Volumes/*`, because right after a
  replug `diskutil` can briefly return nothing while the volume is already
  mounted.

## Requirements

macOS. Nothing else. `lsof` is used to name blocking processes; without root
it only sees your own processes, so Time Machine is reported separately from
its own status.
