# Conventional Commits with Python `pre-commit` and commitlint

Use the Python **pre-commit** framework to check Git commit messages with **`@commitlint/config-conventional`**. This works for commits made in VS Code or from the terminal, and does **not** require Husky or a project `package.json`.

> **Prerequisites:** Git, Python, `pre-commit`, and Node.js/npm for running commitlint. The hook runs in a pre-commit-managed Node environment.

## 1. Install `pre-commit`

With `uv`:

```bash
uv add --dev pre-commit
```

Or with pip:

```bash
python -m pip install pre-commit
```

## 2. Create `.pre-commit-config.yaml`

At the repository root:

```yaml
default_install_hook_types: [pre-commit, commit-msg]

repos:
  - repo: local
    hooks:
      - id: commitlint
        name: Validate Conventional Commit message
        entry: commitlint --edit
        language: node
        stages: [commit-msg]
        additional_dependencies:
          - '@commitlint/cli'
          - '@commitlint/config-conventional'
```

The `commit-msg` stage passes Git's commit-message file to `commitlint --edit` automatically. For reproducible builds, pin the two npm packages to compatible, tested versions.

## 3. Create `commitlint.config.cjs`

```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat', 'fix', 'docs', 'style', 'refactor', 'perf',
        'test', 'build', 'ci', 'chore', 'revert'
      ],
    ],
    'header-max-length': [2, 'always', 100],
  },
};
```

## 4. Install the Git hooks

If using `uv`:

```bash
uv run pre-commit install --install-hooks
```

If using pip:

```bash
pre-commit install --install-hooks
```

Both commands install the `pre-commit` and `commit-msg` hook types configured above.

## 5. Test

**Accepted**:

```bash
git commit -m "feat(tracking): add object tracking"
git commit -m "fix(camera): resolve timeout"
git commit -m "docs: update installation guide"
```

**Rejected**:

```bash
git commit -m "updated code"
```

Common prefixes: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `style`, `revert`.

Format: `type(optional-scope): description`.

## 6. Share with the team

Commit these files:

```text
.pre-commit-config.yaml
commitlint.config.cjs
pyproject.toml   # when pre-commit is a uv dev dependency
uv.lock          # when using uv
```

After cloning, each developer runs:

```bash
uv sync
uv run pre-commit install --install-hooks
```

The hook also checks commits created with **VS Code Source Control**. Note that local hooks can be bypassed with `git commit --no-verify`; use CI validation if enforcement must be mandatory.

**Reference:** [commitlint documentation](https://commitlint.js.org/guides/local-setup.html) · [pre-commit documentation](https://pre-commit.com/)
