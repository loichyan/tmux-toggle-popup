# 🌀 tmux-toggle-popup

A handy plugin that helps create toggleable popups.

[demo.webm](https://github.com/loichyan/tmux-toggle-popup/assets/73006950/99a94285-3839-4fe0-949f-5649ad34d5a5)

<details>
<summary>Environment</summary>
<br>

- DE: [Gnome 46](https://release.gnome.org/46) & [PaperWM](https://github.com/paperwm/PaperWM)
- Tmux: [Catppuccin theme](https://github.com/catppuccin/tmux)
- Font: [Rec Mono Duotone](https://www.recursive.design)
- Keystrokes: [Show Me the Key](https://showmethekey.alynx.one)
- Rickroll: [rickrollrc](https://github.com/keroserene/rickrollrc)

_Check
[the dotfiles](https://github.com/loichyan/dotfiles/tree/5899f0e7572de4102261051277b22990e53f8bed)
for more details_

</details>

## 📦 Installation

### Requirements

- Tmux >= **3.4** (not tested on earlier versions)

### With [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add this plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin "loichyan/tmux-toggle-popup"
```

### Manual installation

Clone this repo:

```sh
git clone https://github.com/loichyan/tmux-toggle-popup ~/clone/path
```

Add this line to the bottom of `.tmux.conf`:

```tmux
run ~/clone/path/toggle-popup.tmux
```

Reload Tmux environment with: `tmux source-file ~/.tmux.conf`. You should now be able to use the
plugin.

## ✍️ Usage

Create keybindings to toggle your preferred shell and
[lazygit](https://github.com/jesseduffield/lazygit):

```tmux
bind -n M-t run "#{@popup-toggle} -Ed'#{pane_current_path}' -w75% -h75%"
bind -n M-g run "#{@popup-toggle} -Ed'#{pane_current_path}' -w90% -h90% --name=lazygit lazygit"
```

## ⚙️ Options

### `@popup-socket-name`

**Default**: `popup`

**Description**: The socket name (`tmux -L {@popup-socket-name} ...`) of the server in which all
popup sessions are opened.

### `@popup-id-format`

**Default**: `#{b:socket_path}/#{session_name}/#{b:pane_current_path}/#{@popup_name}`

**Description**: A format string used to generate IDs for each popup, allowing you to customize how
popups are shared across sessions, windows and panes. By default, popups are independent across
sessions, and within each session, popups are shared among the same project (identified by the
directory name). A variable named `@popup_name` is assigned the name of the popup during the
expansion of the format string.

### `@popup-on-open`

**Default**: `set exit-empty off \; set status off`

**Example**:

```tmux
set -g @popup-on-open '
  set exit-empty off
  set status off
'
# escaping "\;" is required when binding key to multiple commands
set -g @popup-on-init '
  bind M-r display "some text" \\\; display "another text"
'
```

**Description**: Run extra commands in the popup every time after it's opened.

### `@popup-on-close`

**Default**: empty

**Description**: Similar to `@popup-on-open`, but executed before the popup is closed.

## ⌨️ Keybindings

### `@popup-toggle`

**Example**:

```tmux
bind -n M-t run "#{@popup-toggle} -Ed'#{pane_current_path}' -w75% -h75%"
```

**Description**: A shell script to toggle a popup: when invoked within a popup of the same name, it
closes the popup; otherwise, it opens a popup of the specified name. If no arguments are provided
and called within a popup, it will close the popup.

```text
USAGE:

  toggle.sh [OPTION]... [COMMAND]...

OPTION:

  --name <name>  Popup name [Default: "default"]
  -[BCE]         Flags passed to display-popup
  -[bcdehsStTwxy] <value>
                 Options passed to display-popup

EXAMPLES:

  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
```

## ⚖️ License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.
