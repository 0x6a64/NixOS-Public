{
  description = "Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Python version - change to python311, python312, etc. as needed
        python = pkgs.python312;

        # Python packages from nixpkgs
        pythonPackages = python.withPackages (ps: with ps; [
          # Core development
          pip
          virtualenv
          setuptools
          wheel

          # Common libraries (uncomment as needed)
          # requests
          # numpy
          # pandas
          # matplotlib
          # pytest
          # black
          # ruff
          # mypy
          # ipython
          # jupyter

          # Web development
          # flask
          # django
          # fastapi
          # uvicorn

          # Data science
          # scikit-learn
          # scipy
          # seaborn
        ]);

      in {
        devShells.default = pkgs.mkShell {
          name = "python-dev";

          buildInputs = [
            pythonPackages

            # Development tools
            pkgs.ruff          # Fast Python linter
            pkgs.pyright       # Python type checker (for VSCode)

            # Optional: Uncomment as needed
            # pkgs.poetry      # Dependency management
            # pkgs.pipenv      # Alternative dependency management
            # pkgs.pre-commit  # Git hooks
          ];

          shellHook = ''
            echo "Python development environment loaded"
            echo "Python version: $(python --version)"

            # Create a local virtual environment for pip-installed packages
            if [ ! -d .venv ]; then
              echo "Creating virtual environment in .venv/"
              python -m venv .venv
            fi

            # Activate the virtual environment
            source .venv/bin/activate

            # Install requirements if present
            if [ -f requirements.txt ]; then
              echo "Installing requirements.txt..."
              pip install -q -r requirements.txt
            fi

            # Set up environment variables
            export PYTHONDONTWRITEBYTECODE=1
            export PYTHONUNBUFFERED=1

            echo ""
            echo "Commands available:"
            echo "  python    - Python interpreter"
            echo "  pip       - Package installer (in .venv)"
            echo "  ruff      - Fast linter"
            echo "  pyright   - Type checker"
          '';
        };
      }
    );
}
