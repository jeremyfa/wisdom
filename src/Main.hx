
import js.Browser.document;
import js.Browser.window;
import markup.ClassModule;
import markup.HtmlDomApi;
import markup.Markup.h;
import markup.Markup.v;
import markup.Markup;
import markup.StyleModule;

function main() {

    final markup = new Markup([ClassModule.module(), StyleModule.module()], new HtmlDomApi());
    var container:Any = document.getElementById('container');

    container = markup.patch(container, h('div', [
        h('p', v({ style: { color: 'blue' }, classes: 'one' }), 'Hello World!'),
    ]));

    var ticks = 1;
    window.setInterval(() -> {

        container = markup.patch(container, h('div', [
            h('p', v({ style: { color: ticks % 2 == 0 ? 'green' : 'purple' }, classes: 'one two ticks-' + ticks }), 'Ticking'),
            h('p',
                h('code', 'ticks: ' + ticks)
            )
        ]));

        ticks++;

    }, 1000);

}
