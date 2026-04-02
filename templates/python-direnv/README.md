# Python Development Environment Template

This template provides a reproducible Python development environment using Nix flakes and direnv.

## Setup

1. **Copy to your project:**
   ```bash
   cp -r ~/Nixos/templates/python-direnv/* /path/to/your/project/
   ```

2. **Allow direnv in the directory:**
   ```bash
   cd /path/to/your/project
   direnv allow
   ```

3. **Customize `flake.nix`:**
   - Uncomment the Python packages you need
   - Change Python version if needed (python311, python312, python313)
   - Add any additional system packages

## How it works

- **`flake.nix`**: Defines the Nix development environment with Python and tools
- **`.envrc`**: Tells direnv to load the flake when you enter the directory
- **`.venv/`**: Created automatically for pip-installed packages

## Usage

Once set up, the environment loads automatically when you `cd` into the directory:

```bash
cd my-project
# Environment loads automatically...
# "Python development environment loaded"

python --version  # Your configured Python version
pip install some-package  # Installs to .venv/
```

## Files to .gitignore

Add these to your `.gitignore`:
```
.direnv/
.venv/
.env
```

## Adding pip packages

For packages not in nixpkgs or for project-specific dependencies:

```bash
pip install some-package
pip freeze > requirements.txt
```

The `requirements.txt` will be auto-installed on next environment load.
