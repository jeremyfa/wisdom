# Wisdom

A portable and modular virtual DOM library for [Haxe](https://haxe.org), with inline markup support.

Started as port of [snabbdom](https://github.com/snabbdom/snabbdom), rewritten to Haxe and extended to provide additional features.

**⚠️ Currently under active development, not ready for use yet!**

## Roadmap

Current focus is `JS` target in the browser to manipulate HTML DOM elements, but the library is designed to work with any hierarchy of elements, even on native Haxe targets such as `C++`, as long as you provide a corresponding `Backend` implementation. In other words, this library is not specific to HTML5 or the Web browser and could be used in other contexts!

- [x] Initial port of snabbdom core
- [x] HTML backend
- [x] Additional modules (in progress)
- [x] Haxe Inline XML (JSX-like feature)
- [ ] Some actual documentation

## Syntax highlighting

Wisdom uses it's own markup syntax, surrounted with `'<>` and `'` tokens. That is, you write your markup inside a single-quoted string that starts with `<>`.

By default, this markup won't be syntax highlighted in VSCode, but you can install the [haxe-wisdom VSCode extension](https://marketplace.visualstudio.com/items?itemName=jeremyfa.haxe-wisdom) to support it.

![haxe wisdom markup syntax highlighting](https://github.com/jeremyfa/vscode-haxe-wisdom/blob/main/images/wisdom-syntax.png?raw=true)

## Credits

This library has been ported, adapted to Haxe and extended by **Jérémy Faivre** from the work of **Simon Friis Vindum** who created the _very well designed_ [snabbdom](https://github.com/snabbdom/snabbdom) ⚡️ library.
