// Visual check of the Golden Layout integration in a real Chromium.
//
// Serves this directory, drives the page with Playwright, asserts geometry
// (jsdom cannot measure anything), exercises a tab drag & drop, and leaves
// screenshots in shots/ for a human (or a model) to look at.
import { createServer } from 'node:http';
import { readFile, mkdir } from 'node:fs/promises';
import { dirname, extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const root = dirname(fileURLToPath(import.meta.url));
const shots = join(root, 'shots');
await mkdir(shots, { recursive: true });

const mime = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.png': 'image/png', '.map': 'application/json' };
const server = createServer(async (req, res) => {
    const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname));
    const file = join(root, path === '/' ? 'index.html' : path);
    try {
        const body = await readFile(file);
        res.writeHead(200, { 'content-type': mime[extname(file)] ?? 'application/octet-stream' });
        res.end(body);
    }
    catch {
        res.writeHead(404);
        res.end();
    }
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}/`;

let failures = 0;
const check = (what, ok, got) => {
    console.log((ok ? 'PASS ' : 'FAIL ') + what + (ok ? '' : ' (got ' + JSON.stringify(got) + ')'));
    if (!ok) failures++;
};
const rect = (page, selector, index = 0) => page.evaluate(([s, i]) => {
    const el = document.querySelectorAll(s)[i];
    return el ? el.getBoundingClientRect().toJSON() : null;
}, [selector, index]);
const inside = (a, b) => a.left >= b.left - 1 && a.top >= b.top - 1 && a.right <= b.right + 1 && a.bottom <= b.bottom + 1;
const overlap = (a, b) => a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom;
const count = (page, selector) => page.evaluate(s => document.querySelectorAll(s).length, selector);

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
const pageErrors = [];
page.on('pageerror', e => pageErrors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') pageErrors.push(m.text()); });

try {
    await page.goto(url);
    await page.waitForSelector('.lm_content', { timeout: 5000 });
    await page.waitForTimeout(300);

    // 1. Initial geometry
    check('two containers', await count(page, '.lm_content') === 2, await count(page, '.lm_content'));
    const c0 = await rect(page, '.lm_content', 0);
    const c1 = await rect(page, '.lm_content', 1);
    check('containers have a size', c0.width >= 100 && c0.height >= 100 && c1.width >= 100 && c1.height >= 100, [c0, c1]);
    check('containers do not overlap', !overlap(c0, c1), [c0, c1]);
    const editor = await rect(page, '.pane.editor');
    const consolePane = await rect(page, '.pane.console');
    check('editor pane fills its container', editor && inside(editor, c0) && editor.width >= c0.width - 2 && editor.height >= c0.height - 2, [editor, c0]);
    check('console pane fills its container', consolePane && inside(consolePane, c1) && consolePane.width >= c1.width - 2, [consolePane, c1]);
    check('editor wider than console (60/40)', editor.width > consolePane.width, [editor.width, consolePane.width]);
    check('header buttons present', await count(page, '.lm_controls .gl-add') === 2, await count(page, '.lm_controls .gl-add'));
    await page.screenshot({ path: join(shots, '01-initial.png') });

    // 2. Reactivity inside a panel
    await page.click('#inc');
    await page.click('#inc');
    await page.waitForTimeout(100);
    check('count in bar', (await page.textContent('#count')).trim() === '2', await page.textContent('#count'));
    check('count in panel', (await page.textContent('.pane-count')).trim() === '2', await page.textContent('.pane-count'));

    // 3. Drag the Console tab onto the Editor stack
    await page.evaluate(() => document.querySelector('.pane.console').setAttribute('data-mark', 'yes'));
    const tab = await page.evaluate(() => {
        const tabs = [...document.querySelectorAll('.lm_tab')];
        const t = tabs.find(t => t.querySelector('.lm_title')?.textContent.trim() === 'Console');
        return t ? t.getBoundingClientRect().toJSON() : null;
    });
    check('console tab found', tab != null, tab);
    if (tab) {
        // Dropping on a stack's header adds the tab to that stack; the body is
        // split into top/right/bottom/left zones that would split the layout.
        const header = await rect(page, '.lm_header', 0);
        const from = { x: tab.left + tab.width / 2, y: tab.top + tab.height / 2 };
        const to = { x: header.left + header.width * 0.4, y: header.top + header.height / 2 };
        await page.mouse.move(from.x, from.y);
        await page.mouse.down();
        await page.waitForTimeout(250);
        const steps = 12;
        for (let i = 1; i <= steps; i++) {
            await page.mouse.move(from.x + (to.x - from.x) * i / steps, from.y + (to.y - from.y) * i / steps);
            await page.waitForTimeout(30);
        }
        await page.waitForTimeout(100);
        await page.mouse.up();
        await page.waitForTimeout(400);
    }
    const afterDrag = await page.evaluate(() => {
        const con = document.querySelector('.pane.console');
        const ed = document.querySelector('.pane.editor');
        return {
            marked: con?.getAttribute('data-mark') === 'yes',
            sameStack: con && ed && con.closest('.lm_stack') === ed.closest('.lm_stack'),
            contents: document.querySelectorAll('.lm_content').length,
            stacks: document.querySelectorAll('.lm_stack').length,
            count: document.querySelector('.pane-count')?.textContent.trim()
        };
    });
    check('console pane element preserved through drag', afterDrag.marked, afterDrag);
    check('console tab now in the editor stack', afterDrag.sameStack && afterDrag.stacks === 1, afterDrag);
    check('state preserved through drag', afterDrag.count === '2', afterDrag);
    await page.screenshot({ path: join(shots, '02-after-drag.png') });

    // 4. Open a panel through the component API
    await page.click('#open-notes');
    await page.waitForTimeout(300);
    check('three containers after open', await count(page, '.lm_content') === 3, await count(page, '.lm_content'));
    const notes = await rect(page, '.pane.notes');
    check('notes pane has a size', notes && notes.width >= 100 && notes.height >= 100, notes);
    await page.screenshot({ path: join(shots, '03-notes.png') });

    // 5. Close the Console tab with its close button
    const closed = await page.evaluate(() => {
        const tabs = [...document.querySelectorAll('.lm_tab')];
        const t = tabs.find(t => t.querySelector('.lm_title')?.textContent.trim() === 'Console');
        const btn = t?.querySelector('.lm_close_tab');
        if (!btn) return false;
        btn.dispatchEvent(new MouseEvent('click', { bubbles: true }));
        return true;
    });
    await page.waitForTimeout(300);
    check('console close button clicked', closed, closed);
    check('console pane gone', await count(page, '.pane.console') === 0, await count(page, '.pane.console'));

    // 6. Unmount and mount the whole layout
    await page.click('#toggle');
    await page.waitForTimeout(300);
    check('layout unmounted', await count(page, '.lm_goldenlayout') === 0 && await count(page, '.panel') === 0, [await count(page, '.lm_goldenlayout'), await count(page, '.panel')]);
    await page.click('#toggle');
    await page.waitForTimeout(400);
    check('layout mounted again', await count(page, '.lm_content') === 2, await count(page, '.lm_content'));
    const again = await rect(page, '.pane.editor');
    check('editor pane sized again', again && again.width >= 100 && again.height >= 100, again);
    check('panel state follows the model after remount', (await page.textContent('.pane-count')).trim() === '2', await page.textContent('.pane-count'));
    await page.screenshot({ path: join(shots, '04-remounted.png') });

    check('no page errors', pageErrors.length === 0, pageErrors);
}
catch (e) {
    failures++;
    console.log('FAIL exception: ' + (e && e.stack || e));
}
finally {
    await browser.close();
    server.close();
}
console.log(failures === 0 ? 'ALL PASS' : failures + ' FAILURE(S)');
process.exit(failures === 0 ? 0 : 1);
