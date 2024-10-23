package;

import js.Browser.document;
import js.Browser.window;
import markup.HtmlBackend;
import markup.Markup.h;
import markup.Markup.v;
import markup.Markup;
import markup.modules.AttributesModule;
import markup.modules.ClassModule;
import markup.modules.ListenersModule;
import markup.modules.PropsModule;
import markup.modules.StyleModule;

function main() {

    final markup = new Markup([ClassModule.module(), StyleModule.module(), PropsModule.module(), AttributesModule.module(), ListenersModule.module()], new HtmlBackend());
    var container:Any = document.getElementById('container');

    container = markup.patch(container, h('div', [
        h('p', v({
            style: {
                color: 'blue'
            },
            classes: 'one',
            props: {
                align: 'left',
                valign: 'top'
            },
            on: {
                click: () -> { trace('CLICKED!'); }
            }
        }), 'Hello World!'),
    ]));

    var handler = () -> { trace('CLICKED!'); };

    var ticks = 1;
    window.setInterval(() -> {

        container = markup.patch(container, h('div', [
            h('p', v({
                style: {
                    color: ticks % 2 == 0 ? 'green' : 'purple'
                },
                classes: 'one two ticks-' + ticks,
                props: {
                    align: ticks % 2 == 0 ? 'left' : null,
                    valign: 'top'
                },
                on: {
                    click: handler
                }
            }), 'Ticking'),
            h('p',
                h('code', 'ticks: ' + ticks)
            )
        ]));

        ticks++;

    }, 1000);

}
