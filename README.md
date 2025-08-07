# 🌀 tmux-toggle-popup

A handy plugin to create toggleable popups.

[toggle-popup-demo.webm](https://github.com/user-attachments/assets/faf45582-50c5-4efb-86cb-1f1d0e4d95a9)

<details>
<summary>Information</summary>

- font: [0xProto](https://github.com/0xType/0xProto)
- tmux: [tmux-base16](https://github.com/loichyan/tmux-base16)
- Neovim: [Meowim](https://github.com/loichyan/Meowim)

</details>

## 📦 Installation

### Requirements

- tmux >= **3.4** (not tested on earlier versions)

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
```

For more information check out the [usage](USAGE.md).

## ⚖️ License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or
  <http://opensource.org/licenses/MIT>)

at your option.
