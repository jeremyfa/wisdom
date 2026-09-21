package;

import js.Browser.document;
import tracker.Observable;
import ui.GoldenLayout;
import ui.Panel;
import wisdom.HtmlBackend;
import wisdom.Wisdom;
import wisdom.X;
import wisdom.modules.AttributesModule;
import wisdom.modules.ClassModule;
import wisdom.modules.ListenersModule;
import wisdom.modules.PropsModule;
import wisdom.modules.StyleModule;

class VisualState implements Observable {

    public function new() {}

    @observe public var shown:Bool = true;

    @observe public var count:Int = 0;

}

/**
 * The page check.mjs drives: a bar of controls and the reference GoldenLayout
 * component below it, with three panels of distinct colours.
 */
class VisualMain implements X {

    static var st:VisualState;

    static final CONFIG:Dynamic = {
        root: {
            type: 'row',
            content: [
                { type: 'component', componentType: 'editor', title: 'Editor', size: '60%' },
                { type: 'component', componentType: 'console', title: 'Console', size: '40%' }
            ]
        }
    };

    public static function main() {

        st = new VisualState();

        final wisdom = new Wisdom([
            ClassModule.module(), StyleModule.module(), PropsModule.module(), AttributesModule.module(), ListenersModule.module()
        ], new HtmlBackend());

        wisdom.reactive(document.getElementById('container'), () -> '<>
            <div style=${{ display: 'flex', flexDirection: 'column', height: '100%', fontFamily: 'sans-serif' }}>
                <div class="bar" style=${{ display: 'flex', gap: '8px', alignItems: 'center', padding: '8px', background: '#222', color: '#eee' }}>
                    <button id="toggle" onclick=${() -> st.shown = !st.shown}>Toggle layout</button>
                    <button id="open-notes" onclick=${() -> GoldenLayout.last.open('notes', 'Notes')}>Open notes</button>
                    <button id="inc" onclick=${() -> st.count++}>Increment</button>
                    <span id="count">${st.count}</span>
                </div>
                <div style=${{ flex: '1', minHeight: '0' }}>
                    <if ${st.shown}>
                        <GoldenLayout config=$CONFIG>
                            <Panel name="editor">
                                <div class="pane editor" style=${{ background: '#2b3a55', color: '#fff', height: '100%', padding: '12px', boxSizing: 'border-box' }}>
                                    Editor <span class="pane-count">${st.count}</span>
                                </div>
                            </Panel>
                            <Panel name="console">
                                <div class="pane console" style=${{ background: '#3a552b', color: '#fff', height: '100%', padding: '12px', boxSizing: 'border-box' }}>Console</div>
                            </Panel>
                            <Panel name="notes">
                                <div class="pane notes" style=${{ background: '#55352b', color: '#fff', height: '100%', padding: '12px', boxSizing: 'border-box' }}>Notes</div>
                            </Panel>
                        </GoldenLayout>
                    </if>
                </div>
            </div>
        ');

    }

}
