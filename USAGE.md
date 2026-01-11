# 🌀 Usage

<h2 id="lifecycle"> 🔄 Lifecycle </h2>

<!--
Some terms are emphasized in italics. Most of them are referred in the this section.
-->

Every popup is associated with a unique tmux session, namely the *popup
session*, specified by an ID. When you open a popup through `@popup-toggle`:

1. A *popup window* is created by `display-popup`,
2. A tmux session specified by the given ID is created by `new-session` with the
   supplied program in the *popup server* if it does not already exist.
3. Finally, the focus attaches to that session in the *popup window*.

The session from which you call `@popup-toggle` is the *working session*, or the
*caller session*. Similarly, the pane where `@popup-toggle` runs is referred as
the *caller pane*. In a *popup session*, you can invoke `@popup-toggle` again to
close it and return to the *working session*. Closing a *popup session* does not
exit it; instead, it keeps alive until the program running inside it exits.

In a *working session*, invoking `@popup-toggle` will always open a popup
window. However, in a *popup session*, only if the specified ID matches the
current *popup session*, it will close it. Otherwise, the behavior depends on
`@popup-toggle-mode`. For example, if you are in *popup session A*, which was
opened from *working session W*, and you call `@popup-toggle` with an ID
specified as *B*:

- When `@popup-toggle-mode` is set to `switch`, the *popup window* keeps open,
  but the attached session switches to *popup session B*.
- When set to `force-close`, *popup session A* is detached, and then the *popup
  window* closes. This moves the focus back to *working session W*.
- When set to `force-open`, a nested *popup window* is opened in *popup session
  A*, and the focus is then attached to *popup session B* in that window.

In the third case, tmux allows for nearly infinitely nested *popup windows*,
though this is not particularly useful.

## ⌨️ Commands

A command is an executable shell script exported by this plugin, which you can
bind keys to. You can use the `--help` flag to view the usage of each command.

### `@popup-toggle`

**Description**: The core command to manage *popup sessions*. It supports all
options of `display-popup` to customize the style and position of *popup
windows* and the environments of *popup sessions*.

The ID of the target *popup session* is generated from `@popup-id-format` or
taken directly from `--id <id>`. When both are available, `--id` takes
precedence. Instead of specifying the ID each time, you can also use
`--name <name>` combined with `@popup-id-format` to create a template for new
IDs.

When setting key bindings in your *.tmux.conf*, ensure they are loaded in both
the default tmux server and the *popup server*. Otherwise, the assigned hotkeys
may not function properly. In some situations, you may want to define key
bindings outside of *.tmux.conf*. In that case, the key should be assigned in
both the working server and the *popup server*. `@popup-toggle` supports using
`--toggle-key <key>` to achieve this, where `<key>` is passed to `bind-key` and
can include any options supported by `bind-key`. For example, you can use
`--toggle-key '-Troot M-t'` or `--toggle-key '-n M-t'` to bind `M-t` without the
prefix key.

A *popup session* starts in the path of its *caller session*, which is the
default behavior of `display-popup`. You can use `-d <path>` to override this.
Additionally, you may use `{popup_caller_path}` or `{popup_caller_pane_path}` to
specify the start directory, which will **always** be substituted with the path
of the *caller session* and the path of the *caller pane*, respectively. They
serve as context-aware alternatives to `#{session_path}` and
`#{pane_current_pane}`, and are therefore recommended for use in place of the
latter ones.

### `@popup-focus`

**Description**: A helper command to manually send focus events. This is
intended as a workaround for [tmux/tmux#3991], which has been fixed in
[tmux/tmux@a869693].

[tmux/tmux#3991]: https://github.com/tmux/tmux/issues/3991
[tmux/tmux@a869693]: https://github.com/tmux/tmux/commit/a869693405f99c8ca8e2da32a08534489ce165f2

> [!NOTE]
>
> The fix has been included in tmux v3.6, so this command is no longer
> necessary.

You can use `--leave` or `--enter` to send the focus enter event and the focus
leave event, respectively. It also accepts a list of programs that should
receive the specified event. If a program list is supplied, the event is sent
only if the currently running program matches any of them; otherwise, the event
is sent regardless.

**Example**:

```tmux
set -g @popup-before-open 'run "#{@popup-focus} --leave nvim emacs"'
set -g @popup-after-close 'run "#{@popup-focus} --enter nvim emacs"'
```

## ⚙️ Options

You can set a few options before loading this plugin to override the default
values. Most of these options are used to customize the behavior of
`@popup-toggle`, which can also be specified as shell arguments for on-the-fly
overrides.

### `@popup-id-format`

**Default**:
`#{b:socket_path}/#{session_name}/#{b:pane_current_path}/{popup_name}`

**Description**: A format string used to generate a unique ID for each *popup
session*.

This option is primarily used to define how *popup sessions* are shared across
sessions, windows, and panes. You can use `{popup_name}` (not `#{popup_name}`)
as a placeholder for the name of a popup. Below explains how the default value
works:

```text
#{b:socket_path}/#{session_name}/#{b:pane_current_path}/{popup_name}
  ^^^^^^^^^^^^^    ^^^^^^^^^^^^    ^^^^^^^^^^^^^^^^^^^   ^^^^^^^^^^
  (1)              (2)             (3)                   (4)
```

1. Each server has its own popups. If only one server is used, this part can be
   removed.
2. Popups are also independent among different sessions.
3. In each session, popups are shared within the same project, where a project
   is identified by its working directory.
4. Different popups do not share the same ID. This part is usually necessary
   unless you have only one popup set up.

### `@popup-toggle-mode`

**Default**: `switch`

**Description**: Defines the default toggle mode of `@popup-toggle`. See
[lifecycle](#lifecycle) for how each option works.

### `@popup-socket-name`

**Default**: `popup`

**Description**: The socket name of the server to start *popup sessions*.

Generally, it's not recommended to open popups in the default server, as this
plugin may start many sessions depending on your use, which can be quite
annoying when you open the session selector. When starting the designated
server, the environment variable `$TMUX_POPUP_SERVER` is set to the server name.
This is particularly useful for distinguishing *popup servers* from the default
working server in your *.tmux.conf*.

**Example**:

```tmux
# Load configurations specific for popup servers
%if "$TMUX_POPUP_SERVER"
    set -g exit-empty off
    set -g status off
%endif
```

### `@popup-socket-path`

**Default**: empty

**Description**: The socket path of the server to start *popup sessions*.

This option takes precedence over `@popup-socket-name` if both are provided.
When it takes effect, `$TMUX_POPUP_SERVER` is set to the basename of its value.

### `@popup-autostart`

**Default**: `off`

**Description**: Indicates whether to start the *popup server* automatically
when this plugin is loaded. The latency of the first call of `@popup-toggle`
will be significantly reduced with this option enabled, though it does not
affect subsequent calls.

## 🪝 Hooks

A hook is used to run tmux commands on certain events. Each hook is preprocessed
by *xargs(1)*, which splits it into a token stream. The token stream is
collected and passed to tmux when the corresponding event fires. When writing
hooks, keep the following rules in mind:

1. Two commands must be delimited by a semicolon (`;`).
2. Line breaks are replaced with spaces, therefore, as rule *(1)* states,
   remember to put a semicolon after each command.
3. Tokens can be protected by quotes (either `'` or `"`) from being split.
4. Any character preceded by a backslash (`\`) is treated as a literal escape.
   For instance, `\n` is interpreted as `n` rather than a line break.
5. For commands that take a command sequence as an argument, each command in
   that sequence must be delimited by `\;`, just as you would do in
   *.tmux.conf*. You can use either `\\;` or `'\;'` to input a `\;`.
   Additionally, you may also put the entire sequence in a pair of quotes, as
   the following example shows.

To disable a hook, you should set it to `nop` instead of an empty string.

**Example**:

```tmux
# Hide the statusline and setup additional key bindings
set -g  @popup-on-init 'set status off'
# In single quotes, no escape sequence will be recognized.
set -ga @popup-on-init '
  ; bind -n M-1 confirm -p"inside a popup?" "run true" \\; display -d3000 "of course!"
'
# While in double quotes, escape sequences work as usual.
set -ga @popup-on-init "
  ; bind -n M-2 \"confirm -p'inside a popup?' 'run true' ; display -d3000 'of course!'\"
"
```

### `@popup-on-init`

**Default**: `set exit-empty off ; set status off`

**Description**: Runs in the *popup session* when it is attached.

### `@popup-before-open`

**Default**: empty

**Description**: Runs in the *caller session* before entering a *popup window*.

### `@popup-after-close`

**Default**: empty

**Description**: Runs in the *caller session* after leaving a *popup window*.

## 👩‍🍳 Recipes

### Sharing tmux buffers

Forward the output of copies from *popup sessoins* to the the *working session*
and the input of pastes in reverse.

```tmux
%if "$TMUX_POPUP_SERVER"
	set -g copy-command "tmux -Ldefault loadb -w -"
	bind -T prefix ] run "tmux -Ldefault saveb - | tmux loadb -" \; pasteb -p
	bind -T copy-mode-vi y send -X copy-pipe-and-cancel
	bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel
%endif
```

### Popups in working server

```tmux
# Start popups in the working server
set -gF @popup-socket-path "#{socket_path}"
# Turn off statusline
set -g  @popup-on-init "set status off"
# Simplify the ID format
set -g  @popup-id-format "popup/#{b:pane_current_path}/{popup_name}"
# Filter out popup session in the session selector
bind -T prefix s choose-tree -sf "#{!:#{m:popup/*,#{session_name}}}"
```

**Pros**:

- Does not need to start another server.
- Shares buffers across all sessions.

**Cons**:

- Needs to configure your session manager to exclude *popup sessions*.
- May not play well with
  [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect).

### Popups with a predefined layout

Put this in your *.tmux.conf*:

```tmux
bind -n M-t run "#{@popup-toggle} --on-init='source $HOME/.tmux/layout.conf' program1 ...arguments"
```

and:

```tmux
# ~/.tmux/layout.conf
# `on-init` runs each time we enter the popup session, but we only need to set
# up the layout at the first time.
if -F "#{!:#{@popup_did_init}}" {
   split-window -h program2 ...arguments
   select-layout -t1 main-vertical-mirrored
   set @popup_did_init 1
}
```

> [!NOTE]
>
> Whenever you need to interact with the popup session, do it through the
> `on-init` hook rather than `#{@popup-toggle} some_script.sh`. This is because,
> when running `some_script.sh`, the environments that determine which server
> and session tmux(1) targets still refer to your working session. Consequently,
> tmux commands in `some_script.sh` do not affect the popup session but rather
> your working session.
