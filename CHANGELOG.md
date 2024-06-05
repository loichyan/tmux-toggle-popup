# Changelog

## 0.2.0 (2024-06-05)

### Breaking changes

- Tmux commands are parsed by bash(1), thus semicolons in hooks (`@popup-on-open` and `@popup-on-close`) must now be explicitly escaped or quoted ([#1](https://github.com/loichyan/tmux-toggle-popup/pull/1)).
- `@popup-on-open` is renamed to `@popup-on-init` ([#2](https://github.com/loichyan/tmux-toggle-popup/pull/2)).
- `@popup-on-close` is removed, as it cannot handle popup exits. Instead, consider setting the `client-detached` and `pane-exited` hooks in `@popup-on-init` ([#2](https://github.com/loichyan/tmux-toggle-popup/pull/2)).

### Features

- Add two new hooks: `@popup-before-open` and `@popup-after-close` ([#2](https://github.com/loichyan/tmux-toggle-popup/pull/2)).
- Add `@popup-focus`, primarily used as a workaround of [tmux/tmux#3](https://github.com/tmux/tmux/issues/3991) ([#3](https://github.com/loichyan/tmux-toggle-popup/pull/3)).

## v0.1.0 (2024-05-31)

Initial release.
