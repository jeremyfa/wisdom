// Run the compiled regression tests under node, on a jsdom document.
//
// wisdom's only backend is HtmlBackend, which talks to `window.document`.
// jsdom gives it a real DOM without a browser, so the tests exercise the
// actual backend and modules rather than a mock that could drift from them.
import { JSDOM } from 'jsdom';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// pretendToBeVisual gives requestAnimationFrame, which Golden Layout uses to
// propagate its bubbling events.
const dom = new JSDOM('<!doctype html><html><body></body></html>', { pretendToBeVisual: true });
const w = dom.window;

globalThis.window = w;
globalThis.document = w.document;
// `navigator` is a read-only getter on node's globalThis, and nothing here needs it.
for (const name of ['Node', 'Element', 'HTMLElement', 'Text', 'Comment', 'Event', 'MouseEvent']) {
    globalThis[name] = w[name];
}

// Golden Layout reaches window APIs through globalThis, and jsdom does not
// install them there. Bound to the window so `this` is right.
for (const name of ['addEventListener', 'removeEventListener', 'dispatchEvent', 'getComputedStyle', 'requestAnimationFrame', 'cancelAnimationFrame']) {
    globalThis[name] = w[name].bind(w);
}
// No layout under jsdom: every size is 0 and nothing ever resizes.
class ResizeObserverStub { constructor() {} observe() {} unobserve() {} disconnect() {} }
globalThis.ResizeObserver = ResizeObserverStub;
w.ResizeObserver = ResizeObserverStub;

const require = createRequire(import.meta.url);
require(join(dirname(fileURLToPath(import.meta.url)), 'out', 'test.js'));
