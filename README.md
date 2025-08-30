# 🌀 tmux-toggle-popup

A handy plugin to create toggleable popups.

[![tmux-toggle-popup.webm](https://loichyan.github.io/dotfiles/assets/tmux-toggle-popup-thumbnail.jpg)](https://loichyan.github.io/dotfiles/assets/tmux-toggle-popup.webm)

[Information](https://github.com/loichyan/dotfiles/tree/snapshot#information)

## 📦 Installation

### Requirements

- tmux >= **3.4** (not tested on earlier versions)
- Bash >= **3.2.57**

> [!NOTE]
> This plugin is tested on macOS's built-in Bash through GitHub Actions. That
> said, if you are experiencing issues on macOS, please try upgrading your Bash
> to a newer version or open an issue.

### With [tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add this plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin "loichyan/tmux-toggle-popup"
```

### Manual installation

Clone the repo:

```sh
git clone https://github.com/loichyan/tmux-toggle-popup ~/clone/path
```

Add this line to the bottom of `.tmux.conf`:

```tmux
run ~/clone/path/toggle-popup.tmux
```

Reload tmux environment with: `tmux source ~/.tmux.conf`. You should now be able
to use this plugin.

### Nix (Home Manager)

```nix
config.programs.tmux = {
  enable = true;

  # ...

  plugins = with pkgs; [
    tmuxPlugins.tmux-toggle-popup
    # ...
  ];

  extraConfig = ''
    ...
    # popups
    bind C-t run "#{@popup-toggle} -Ed'#{pane_current_path}' -w75% -h75%"
    bind C-g run "#{@popup-toggle} -Ed'#{pane_current_path}' -w90% -h90% --name=lazygit lazygit"
    ...
  '';
};
```

## 🚗 Quick start

Create keybindings to toggle your default shell and
[lazygit](https://github.com/jesseduffield/lazygit):

```tmux
bind -n M-t run "#{@popup-toggle} -w75% -h75% -Ed'{popup_caller_pane_path}'"
bind -n M-g run "#{@popup-toggle} -w90% -h90% -Ed'{popup_caller_pane_path}' --name=lazygit lazygit"

# Turn on autostart to boost the first call of @popup-toggle.
set -g  @popup-autostart on
# If you prefer to share popups within the same project, regardless of which
# session you are working in, put the following setting to your `.tmux.conf`.
set -gF @popup-id-format "#{b:pane_current_path}/{popup_name}"

# If you are using tmux-continuum, make sure it is loaded before this plugin.
# This is only required when you enable @popup-autostart.
set -g @plugin "tmux-plugins/tmux-continuum"
# Must be loaded after tmux-continuum, as the autostart of popup server can
# disable the autosave of tmux-continuum.
set -g @plugin "loichyan/tmux-toggle-popup"
```

> [!TIP]
> Whenever you update the *.tmux.conf*, remember to reload it in both your
> working session and the popup session; otherwise, keybinding or style changes
> may not reflect in popup sessions.

For more information please check out the [usage](USAGE.md).

## ⚖️ License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or
  <http://opensource.org/licenses/MIT>)

at your option.
