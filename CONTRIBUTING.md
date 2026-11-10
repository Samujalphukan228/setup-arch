# Contributing

Thanks for taking a look at `setup-arch`.

## Local setup

```bash
git clone https://github.com/Samujalphukan228/setup-arch.git
cd setup-arch
npm link
```

`npm link` exposes the `setup-arch` command using the working copy.

## Before opening a pull request

```bash
npm test        # syntax, ShellCheck, package contents, dry-run
npm run lint    # ShellCheck only
```

The suite runs without root, network access or pacman, so it works on any Linux
machine with Bash, Node.js and (optionally) ShellCheck.

## Guidelines

- Keep the installer non-destructive: back up before replacing, and never
  delete user data.
- Never commit secrets, tokens, SSH/GPG keys, browser profiles or Docker volumes.
- Add new packages to `packages/pacman.txt` or `packages/aur.txt`, not inline in
  the installer.
- Update `CHANGELOG.md` and the README when behavior changes.
- Shell scripts must pass `shellcheck` with the repository `.shellcheckrc`.

## Reporting bugs

Open an issue with your Arch version, the command you ran, and the full output.
For security issues see [SECURITY.md](SECURITY.md).
