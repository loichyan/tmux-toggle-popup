# 🌀 tmux-toggle-popup

A handy plugin that helps create toggleable popups.

## 📦 Installation

### Requirements

- TMUX >= **3.4** (not tested on earlier versions)

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

Reload TMUX environment with: `tmux source-file ~/.tmux.conf`. You should now be able to use the
plugin.

## ✍️ Usage

Create keybindings to toggle your preferred shell and
[lazygit](https://github.com/jesseduffield/lazygit):

```tmux
bind -n M-t run "#{@popup-toggle} -E -d '#{pane_current_path}' -w 75% -h 75%"
bind -n M-g run "#{@popup-toggle} -E -d '#{pane_current_path}' -w 90% -h 90% --name lazygit lazygit"
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

**Default**: `set exit-empty off ; set status off`

**Example**:

```tmux
# you can use braces for more concise syntax
set -g @popup-on-open {
  set exit-empty off
  set status off
}
```

**Description**: Run extra commands in the popup every time after it's opened.

### `@popup-on-close`

**Default**: empty

**Description**: Similar to `@popup-on-open`, but executed before the popup is closed.

## ⌨️ Keybindings

### `@popup-toggle`

**Example**:

```tmux
bind -n M-t run "#{@popup-toggle} -E -d '#{pane_current_path}' -w 75% -h 75%"
```

**Description**: A shell script to toggle a popup: when invoked from within a popup of the same
name, it closes the popup; otherwise, it opens a popup of the specified name.

```text
USAGE:

  toggle.sh [OPTION]... [COMMAND]...

OPTION:

  --name <name>  Popup name [Default: "default"]
  -[BCE]         Flags passed to display-popup
  -[bcdehsStTwxy] <value>
                 Options passed to display-popup

EXAMPLES:

  toggle.sh --name bash -E -d '#{pane_current_path}' bash -l
```

## ⚖️ License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.
