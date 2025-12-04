# droid-sandbox

Isolated Podman containers for running [Factory Droid](https://factory.ai/) agents on sensitive code (crypto, financial, etc.).

## What's Included

- **Ubuntu 24.04 LTS** base image
- **Python 3** with pip and venv
- **Node.js 22 LTS** with TypeScript, ts-node
- **Droid CLI** (Factory.ai) pre-installed
- Non-root user for security

## Quick Setup

```bash
# 1. Clone this repo
git clone https://github.com/YOUR_USERNAME/droid-sandbox.git
cd droid-sandbox

# 2. Run setup wizard
./dsb setup
# This will:
# - Prompt for your Factory API key
# - Save it to ~/.config/dsb/api-key (600 permissions)
# - Build the container image
```

## Basic Usage

```bash
# Create a new project
./dsb init my-wallet

# Clone a repo into a project
./dsb clone git@github.com:me/wallet.git my-wallet

# Open shell in container
./dsb shell my-wallet

# Run droid directly
./dsb run my-wallet droid

# Start container in background (keeps running)
./dsb start my-wallet

# Attach to running container
./dsb attach my-wallet
# Detach: Ctrl+P, Ctrl+Q

# Stop background container
./dsb stop my-wallet
```

## Commands

### Project Management
```bash
./dsb init <project>              # Create new project folder
./dsb list                        # List all projects
./dsb clone <git-url> [name]      # Clone repo into project
./dsb destroy <project>           # Remove project
```

### Interactive Mode (stops when terminal closes)
```bash
./dsb shell <project>             # Open bash shell
./dsb run <project> <cmd...>      # Run command (e.g., dsb run my-wallet droid)
```

### Detached Mode (keeps running in background)
```bash
./dsb start <project> [cmd]       # Start in background (default: bash)
./dsb attach <project>            # Connect to running container
./dsb stop <project>              # Stop container
./dsb exec <project> <cmd>        # Run command in running container
./dsb logs <project>              # View logs
```

### Maintenance
```bash
./dsb ps                          # List running containers
./dsb status                      # Show containers, images, disk usage
./dsb build                       # Rebuild image
./dsb clean                       # Remove stopped containers
```

## Workflows

### Working with Droid

Inside the container, your project is at `/home/dev/workspace`:

```bash
# Interactive mode
./dsb shell my-wallet
droid

# Or run droid directly
./dsb run my-wallet droid

# Headless mode
./dsb run my-wallet droid exec "analyze this codebase"
./dsb run my-wallet droid exec --auto low "fix linting errors"
```

### Long-Running Sessions

For work that survives terminal disconnects:

```bash
# Start container in background
./dsb start my-wallet

# Attach to it
./dsb attach my-wallet

# Inside container, start droid
droid

# Disconnect without stopping: Ctrl+P, Ctrl+Q
# Close your terminal, container keeps running

# Later, reattach
./dsb attach my-wallet

# When done
./dsb stop my-wallet
```

### Project Secrets

For project-specific secrets (private keys, etc.):

```bash
# Create .env file in your project
cd projects/my-wallet
echo 'ETH_PRIVATE_KEY=0x...' > .env
echo 'ALCHEMY_API_KEY=...' >> .env
chmod 600 .env

# .env is automatically gitignored
# Load it in your code or source it in the container
```

## Project Structure

```
droid-sandbox/
├── Containerfile          # Container image definition
├── dsb                    # Main CLI script
├── README.md
└── projects/              # Your projects (gitignored)
    ├── my-wallet/
    │   ├── .env          # Project secrets (gitignored)
    │   └── src/...       # Your code
    └── defi-bot/
        └── ...
```

## Secrets Management

- **Droid API key**: Stored in `~/.config/dsb/api-key` (600 permissions)
  - Mounted read-only in container at `/home/dev/.dsb-api-key`
  - Auto-loaded as `FACTORY_API_KEY` environment variable
  - Outside project workspace (isolated from project code)

- **Project secrets**: Create `.env` file in project folder
  - Automatically gitignored
  - Lives inside project workspace
  - Load manually or source in container shell

**Security note**: All code running in the container (including npm packages installed by droid) can access mounted secrets. Only work with trusted code and dependencies.

## Droid Autonomy Levels

Control what Droid can do with the `--auto` flag:

| Level | Flag | Allowed Operations |
|-------|------|-------------------|
| Read-only | (default) | Read files, git status/log/diff, analyze |
| Low | `--auto low` | + Create/edit files in project |
| Medium | `--auto medium` | + npm/pip install, git commit, build |
| High | `--auto high` | + git push, deploy commands |

## Security

- Container runs as non-root user (`dev`)
- Each project isolated in its own container
- API key mounted read-only outside project workspace
- Droid cannot access files outside mounted project
- All project code and secrets stay local (gitignored)

## Requirements

- **Podman**: `sudo apt install podman` (Ubuntu/Debian) or `sudo dnf install podman` (Fedora)
- **Git**: For cloning repos

## Troubleshooting

**Container won't start:**
```bash
./dsb build --force    # Force rebuild image
```

**API key not working:**
```bash
# Check key file exists and has correct permissions
ls -la ~/.config/dsb/api-key
# Should show: -rw------- (600)

# Re-run setup to update key
./dsb setup
```

**Project code not visible in container:**
```bash
# Make sure project exists
./dsb list

# Check SELinux labels (Fedora/RHEL)
ls -laZ projects/my-wallet
```
