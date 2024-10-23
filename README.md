# Markup

A portable and modular virtual DOM library for [Haxe](https://haxe.org), with inline XML support.

Started as port of [snabbdom](https://github.com/snabbdom/snabbdom), rewritten to Haxe and extended to provide additional features.

**⚠️ Currently under active development, not ready for use yet!**

## Roadmap

Current focus is `JS` target in the browser to manipulate HTML DOM elements, but the library is designed to work with any hierarchy of elements, even on native Haxe targets such as `C++`, as long as you provide a corresponding `Backend` implementation. In other words, this library is not specific to HTML5 or the Web browser and could be used in other contexts!

- [x] Initial port of snabbdom core
- [x] HTML backend
- [x] Additional modules (in progress)
- [ ] Haxe Inline XML (JSX-like feature)

## Credits

This library has been ported, adapted to Haxe and extended by **Jérémy Faivre** from the work of **Simon Friis Vindum** who created the _very well designed_ [snabbdom](https://github.com/snabbdom/snabbdom) ⚡️ library.
