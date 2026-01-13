# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Dev Process

- Always run a build before wrapping work. For CLI, use xcodebuild -scheme POILog -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build to avoid signing blocks.
- When adding new Swift files, update POILog.xcodeproj/project.pbxproj so they compile in the target.
- Default to bead tracking: create/claim issues up front, update status as you go, close when done.

