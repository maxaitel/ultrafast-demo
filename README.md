# ultrafast-demo

A macOS launcher for an interactive Codex CLI session using an OpenAI API key, the Ultrafast service tier, and low reasoning effort. It uses a separate provider configuration and stores the API key in macOS Keychain, leaving the saved Codex login and configuration unchanged. API usage is billed to the key's account; Ultrafast uses premium pricing.

## Setup

Requirements: macOS, Xcode command-line tools (Swift), Python 3, zsh, and the Codex CLI on your `PATH`.

```sh
git clone https://github.com/maxaitel/ultrafast-demo.git
cd ultrafast-demo
swiftc ultrafast-demo-keychain.swift -o ultrafast-demo-keychain
./ultrafast-demo --setup-key
./ultrafast-demo
```

Optionally, link the launcher into a directory on your `PATH`:

```sh
mkdir -p ~/.local/bin
ln -s "$PWD/ultrafast-demo" ~/.local/bin/ultrafast-demo
```

Use `ultrafast-demo --key-status` to check for a saved key and `ultrafast-demo --help` for options. Other arguments pass through to Codex. The launcher refreshes its model catalog from the installed CLI on each run and stops if the expected models are absent. Confirm that Codex displays Ultrafast before a demo. Model names, CLI options, and tier availability depend on the installed Codex version and API access.
