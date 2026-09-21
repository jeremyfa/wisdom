# Wisdom

A portable and modular virtual DOM library for [Haxe](https://haxe.org), with inline markup support.

Started as port of [snabbdom](https://github.com/snabbdom/snabbdom), rewritten to Haxe and extended to provide additional features.

**⚠️ Currently under active development, API could change!**

## Roadmap

Current focus is `JS` target in the browser to manipulate HTML DOM elements, but the library is designed to work with any hierarchy of elements, even on native Haxe targets such as `C++`, as long as you provide a corresponding `Backend` implementation. In other words, this library is not specific to HTML5 or the Web browser and could be used in other contexts!

- [x] Initial port of snabbdom core
- [x] HTML backend
- [x] Additional modules (in progress)
- [x] Haxe Inline XML (JSX-like feature)
- [ ] Non-HTML backends?

## Syntax highlighting

Wisdom uses it's own markup syntax, surrounted with `'<>` and `'` tokens. That is, you write your markup inside a single-quoted string that starts with `<>`.

By default, this markup won't be syntax highlighted in VSCode, but you can install the [haxe-wisdom VSCode extension](https://marketplace.visualstudio.com/items?itemName=jeremyfa.haxe-wisdom) to support it.

![haxe wisdom markup syntax highlighting](https://github.com/jeremyfa/vscode-haxe-wisdom/blob/main/images/wisdom-syntax.png?raw=true)

This guide covers the template markup syntax that can be used within '<>' and `'` tokens. The markup provides a powerful way to create structured templates with control flow, components, and dynamic content.

## Basic syntax

Templates are wrapped in single quotes with `<>` marker:

```xml
'<><tag>hello</tag>'
```

_For convenience, the `'<>` and `'` surrounding delimiters will be omitted in the next code examples._

## Components & Elements

### Custom components

Custom components start with an uppercase letter:

```xml
<UserProfile user=$currentUser />

<Button type="primary" onclick=$handleClick>
    Click me
</Button>
```

### Regular elements

Regular elements (HTML elements when using the html backend) start with lowercase letters:

```xml
<div class="container">
    <h1>$title</h1>
    <p class="content">$content</p>
</div>
```

## String interpolation

Wisdom markup is compatible with Haxe's single-quoted string interpolation.

### Basic interpolation

Use `$` for simple variable interpolation:

```xml
<div>Hello, $name!</div>
```

### Expression interpolation

Use `${}` for expressions:

```xml
<div>Total: ${price * quantity}</div>
<div>Full name: ${firstName + " " + lastName}</div>
```

### Escaping

To use literal `$` characters, double them:

```xml
<div>Price: $$99.99</div>
```

## Comments

You can use three types of comments in your markup:

```txt
// Single line comment

/*
    Multi-line
    comment
*/

<!-- XML-style comment -->
```

## Control flow

### If statements

Basic if/else conditional rendering:

```xml
<if ${user.isLoggedIn}>
    Welcome back, ${user.name}!
<else>
    Please log in
</if>
```

With elseif:

```xml
<if ${score >= 90}>
    Grade: A
<elseif ${score >= 80}>
    Grade: B
<elseif ${score >= 70}>
    Grade: C
<else>
    Grade: F
</if>
```

### Foreach loops

Iterate over arrays or iterables:

```xml
<foreach $cities ${(i:Int, city:String) -> '<>
    <li>$i. $city</li>
'} />
```

### Switch statements

```xml
<switch $status>
    <case "active">User is active</case>
    <case "pending">User is pending approval</case>
    <case "suspended">Account suspended</case>
    <default>
        Unknown status
    </default>
</switch>
```

Case values can be any haxe primitive like `123`, `"hello"`, `'world'`, `true`, `false`, `0xFF00FF` or interpolated values (`$value`, `${...}`).

Alternative haxe-style default case is also supported:

```xml
<switch $mood>
    <case "happy"> :) </case>
    <case "sad">   :( </case>
    <case _>       :| </case>
</switch>
```

## Attributes

### Dynamic attributes

Attributes can use expressions:

```xml
<div class=${getClassName()}>
    <input type="text" value=${formData.value} />
    <img src=${"/images/" + imagePath} />
</div>
```

### Conditional attributes

Use if/unless for conditional attributes:

```xml
<div if=${showElement}>
    Conditional content
</div>

<button class="btn" unless=$submitForbidden>
    Submit
</button>
```

### Key attribute

Use the key attribute for optimizing list rendering:

```xml
<ul class="cities">
    <foreach $cities ${(i:Int, city:City) -> '<>
        <li key=${city.id}>
            ${city.name}
        </li>
    '} />
</ul>
```

## Usage in Haxe

### Typical hxml

```ini
# Project setup
-cp src
--main Main
--js html/app.js

# Use wisdom library
--library wisdom

# Use tracker library (optional)
--library tracker

# Use HTML backend
-D wisdom_html
```

### Required imports

```haxe
import wisdom.HtmlBackend;
import wisdom.Wisdom;
import wisdom.X;
import wisdom.modules.AttributesModule;
import wisdom.modules.ClassModule;
import wisdom.modules.ListenersModule;
import wisdom.modules.PropsModule;
import wisdom.modules.StyleModule;
```

### Interfaces to use

Your class must `implement` the `wisdom.X` interface in order to support `'<> ... '` markup syntax.

```haxe
class MyApp implements X {
    ...
}
```

### Basic initialization

```haxe
// Initialize Wisdom with required modules and HTML backend
var wisdom = new Wisdom([
        ClassModule.module(),
        StyleModule.module(),
        PropsModule.module(),
        AttributesModule.module(),
        ListenersModule.module()
    ],
    new HtmlBackend()
);
```

## Binding with an HTML element

### Initial bind

Let's assume our HTML file used to load our code has a `<div id="container"></div>`.

We can use `patch()` to bind our virtual dom to it:

```haxe
// Initial binding with the actual #container HTML element
// (keep a reference to the vdom with the `container` variable)
var container = wisdom.patch(
    document.getElementById('container'),
    '<>
        <div class="my-wisdom-words">
            Some words of wisdom
        </div>
    '
);
```

### Later, patching the virtual dom with new content

```haxe
// Patching again: use the previous `container` reference,
// then replace it with the patched one
container = wisdom.patch(
    container,
    '<>
        <div class="my-wisdom-words">
            More words of wisdom...
        </div>
    '
);
```

`patch()` can be called again and again with new content to update the nodes as needed. The changes will be reflected to the actual HTML page (when using html backend).

## Components

Components are special functions that can be invoked by your wisdom markup:

```haxe
@x function Hello(name:String) '<>
    <div class="hello">
        Hello $name!
    </div>
';
```

### Usage in markup

We now have a component that can take a single parameter `name`. Here is how we can use it in markup:

```xml
<div class="my-markup">

    <Hello name="Jeremy" />

</div>
```

### Children

Components can handle child nodes with the special `children` parameter

```haxe
@x function HelloWithChildren(name:String, children:Array<wisdom.VNode>) '<>
    <div class="hello">
        Hello $name!
        <div class="some-children">
            $children
        </div>
    </div>
';
```

Usage in markup:

```xml
<div class="my-markup">

    <HelloWithChildren name="John">
        <p>Some more content</p>
        <p>And even <strong>more content!</strong></p>
    </HelloWithChildren>

</div>
```

## Reactivity with [tracker](https://github.com/jeremyfa/tracker) library

To enable reactivity, you'l need to have the `tracker` haxe library enabled in your hxml:

```ini
# Use tracker library
--library tracker
```

### Reactive virtual dom

When [tracker](https://github.com/jeremyfa/tracker) is available, you can create reactive virtual dom trees using a single `reactive()` call instead of consecutive `patch()` calls:

```haxe
wisdom.reactive(
    document.getElementById('container'),
    () -> '<>
        <div class="reactive-wisdom">
            The best reaction is wisdom.
            <HelloAndCount name="Jane" />
        </div>
    '
);
```

When using `wisdom.reactive()`, the virtual dom will be patched automatically any time an observable value that it depends on changes.

_Notice the addition of `() -> ` before `'<> ...`. This is because we are providing a function that will be called everytime something it depends on has changed._

### Components with reactive state

You might have noticed we are invoking another component named `HelloAndCount`. Here is how it looks like:

```haxe
/**
 * A reactive component with its own state
 */
@x function HelloAndCount(
    @state count:Int = 0,
    name:String
) {

    function increment() {
        count++;
    }

    return '<>
        <div onclick=$increment>
            Hello $name<br />
            Count: ${count}
        </div>
    ';

}
```

This time, the component provides its own state: any argument prefixed with the `@state` meta will become an observable variable of the component's state. If any of those values are changing, the component will be rendered again and the virtual dom automatically **patched** in reaction.

In this example, clicking on the element will trigger an increment of the `count` variable an make the component render itself again, because it is used within a `wisdom.reactive()` call.

## Third-party DOM libraries

Wisdom normally owns every node under a `reactive()` root. Four small primitives let a third-party library (Golden Layout, CodeMirror, Monaco, Leaflet, a canvas...) own part of that DOM without confusing the diff, the component state tracking or the destruction of components.

### `unmanaged`

An element flagged `unmanaged` is created and updated by Wisdom (classes, style, attributes, listeners) but its DOM children are never created, diffed or removed: the library fills the inside.

```xml
<div class="editor" unmanaged />
```

Such an element must have no children and no text in the markup. Flipping the flag between renders re-creates the element.

### `<portal into=$host>`

A portal renders its children inside `host`, an element owned by someone else (a Golden Layout container, `document.body` for a modal...), while a comment node keeps its position in the parent. The children stay ordinary Wisdom children: they are diffed in place when the parent re-renders, components inside keep their state, and they are destroyed when the portal goes away, exactly as under an `<if>`.

```xml
<portal into=${container.element}>
    <Editor doc=$currentDoc />
</portal>
```

A portal only accepts the attributes `into`, `key`, `if` and `unless`. If `into` changes for the same portal, the existing children are moved to the new host, elements and state intact. When the portal is removed, its children are detached from wherever they currently are, so a library that already cleared or moved its container does not break anything. Portals are keyed by their position automatically, so portals produced by a `<foreach>` never get paired with each other.

### `ref`

`ref` follows the life of an element: the callback receives the element once it is attached (at the end of the patch that created it), and `null` when the element is destroyed. Changing the callback between renders does not call anything.

```xml
<div class="map" unmanaged ref=$bindMap />
```

### `didMount()` / `willUnmount()` on class components

A class component (`extends wisdom.Component`) rendered through `wisdom.reactive()` can override:

- `didMount(elm)`: the root element is attached to the document. Called again after `willUnmount()` if the root element is re-created (root tag changed, or the root was moved by a structural change in the parent).
- `willUnmount()`: the root element is about to leave the DOM (it is still attached), or the component is about to be destroyed. Never called twice without a `didMount()` in between. `destroy()` remains the final cleanup and runs after it.

`elm` is the backend's element (`js.html.Element` with `HtmlBackend`), passed as `Any`. Observable writes inside these callbacks are fine with `-D tracker_web_immediate` (the browser setup), where autorun invalidations are deferred to a microtask.

```haxe
class CodeEditor extends Component {

    var view:EditorView = null;

    function render() '<>
        <div class="editor" unmanaged />
    ';

    override function didMount(elm:Any) {
        view = new EditorView({ parent: elm });
    }

    override function willUnmount() {
        view.destroy();
        view = null;
    }

}
```

### A docking layout, end to end

A library that creates containers and asks you to fill them (Golden Layout) combines the four: an unmanaged root handed to the library in `didMount()`, an observable list of the containers it binds, and one portal per container rendering the matching child. The reference implementation lives in `test/regress/ui/GoldenLayout.hx` (externs in `test/regress/glext/`) and is exercised against the real library by the regression suite and by the visual check below. It is used like this:

```xml
<GoldenLayout config=$layoutConfig>
    <Panel name="editor"><Editor doc=$currentDoc /></Panel>
    <Panel name="console"><Console /></Panel>
</GoldenLayout>
```

where each `componentType` of the layout config names a `<Panel>` child (`name`, not `id`: `tracker.Entity` already declares `id`).

## Limitations

### Roots with single node

Markup roots (reactive component roots, markup roots used with `wisdom.patch()`) should be wrapped into a single node.

Valid:

```xml
<>
    <div>
        <p>node 1</p>
        <p>node 2</p>
    </div>
```

Invalid:

```xml
<>
    <p>root node 1</p>
    <p>root node 2</p>
```

## Tests

Regression tests run under node on a [jsdom](https://github.com/jsdom/jsdom) document, with the real `HtmlBackend` and modules, and the real [golden-layout](https://github.com/golden-layout/golden-layout) for the docking case. They live in `test/regress/`.

```sh
cd test/regress && npm install && cd ../..
haxe build-test.hxml && node test/regress/run.mjs
```

Each check prints `PASS` or `FAIL`, and the process exits with a non-zero code if any check failed.

jsdom does not lay anything out, so `test/visual/` renders the Golden Layout integration in a real Chromium through [Playwright](https://playwright.dev): geometry assertions, a tab drag & drop, and screenshots left in `test/visual/shots/` to look at.

```sh
haxe build-visual.hxml
cd test/visual && npm install && npm run build && npm run check
```

# Credits

This library has been ported, adapted to Haxe and extended by **Jérémy Faivre** from the work of **Simon Friis Vindum** who created the _very well designed_ [snabbdom](https://github.com/snabbdom/snabbdom) ⚡️ library.
