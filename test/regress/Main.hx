package;

import js.Browser.document;
import js.html.Element;
import tracker.Observable;
import wisdom.Component;
import wisdom.HtmlBackend;
import wisdom.ReactiveContext;
import wisdom.VNode;
import wisdom.Wisdom;
import wisdom.X;
import wisdom.modules.AttributesModule;
import wisdom.modules.ClassModule;
import wisdom.modules.ListenersModule;
import wisdom.modules.PropsModule;
import wisdom.modules.StyleModule;

using StringTools;

/**
 * Observable state the test drives from outside, the way an application
 * model drives components. One fresh instance per case.
 */
class State implements Observable {

    public function new() {}

    /** Read by SlotBar: a conditional sibling placed before `$children`. */
    @observe public var inset:Bool = true;

    /** Read by Plain and SlotBar as an attribute: a re-render with no structural change. */
    @observe public var tick:Int = 0;

    /** Read by the root render: a conditional sibling driven by the parent. */
    @observe public var flag:Bool = false;

    /** Read by the root render: keyed list. */
    @observe public var items:Array<String> = ['a', 'b', 'c'];

}

/**
 * The shape of the kit's TitleBar: a conditional sibling right before the
 * slot, toggled by state the component reads itself.
 */
class SlotBar extends Component {

    function render() '<>
        <div class="bar" data-tick=${Main.st.tick}>
            <if ${Main.st.inset}>
                <div class="spacer"></div>
            </if>
            $children
        </div>
    ';

}

/** A slot with nothing else around it. */
class Plain extends Component {

    function render() '<>
        <div class="plain" data-tick=${Main.st.tick}>
            $children
        </div>
    ';

}

/** A component that renders only another component and forwards its slot. */
class Wrapper extends Component {

    function render() '<>
        <SlotBar>
            $children
        </SlotBar>
    ';

}

/** A slot the component itself can hide. */
class Hider extends Component {

    function render() '<>
        <div class="hider">
            <if ${Main.st.flag}>
                $children
            </if>
        </div>
    ';

}

/** Stateless leaf, like the kit's Icon. */
class Icon extends Component {

    @props var kind:String = 'circle';

    function render() '<>
        <i class=${'icon-' + kind}></i>
    ';

}

/** Stateful leaf, re-rendering on its own. */
class Counter extends Component {

    public static var last:Counter = null;

    public static var byLabel:Map<String,Counter> = new Map();

    @props var label:String = '';

    @observe public var count:Int = 0;

    function init() {
        last = this;
        byLabel.set(label, this);
    }

    function render() '<>
        <div class="counter" data-label=$label>Count: $count</div>
    ';

}

/** Stateful component used directly as the slot's child. */
class TopBar extends Component {

    public static var last:TopBar = null;

    @observe public var n:Int = 0;

    function init() {
        last = this;
    }

    function render() '<>
        <div class="topbar">Top $n</div>
    ';

}

class Main implements X {

    public static var st:State;

    static var container:Element;

    static var wisdom:Wisdom;

    static var ctx:ReactiveContext;

    static var caseName:String;

    static var failures:Int = 0;

    static var steps:Array<() -> Void> = [];

    public static function main() {

        case1_rawChildrenNextToConditionalSibling();
        case2_slotAlone();
        case3_componentChildNextToConditionalSibling();
        case4_nestedStatefulComponentInRawChildren();
        case5_parentDrivenConditionalSibling();
        case6_wrapperForwardingSlot();
        case7_keyedListPassingChildren();
        case8_componentWithoutAttributes();
        case9_nestedComponentSurvivesStructuralShift();
        case10_hiddenSlotDestroysItsComponents();

        runSteps();

    }

    /// Cases

    /**
     * The exact shape that failed in the kit: raw markup children, a
     * conditional sibling before them, toggled by the component itself.
     */
    static function case1_rawChildrenNextToConditionalSibling() {

        then(() -> start('1 raw children next to a conditional sibling', () -> '<>
            <div class="root">
                <SlotBar>
                    <div class="title">
                        <Icon kind="sparkles" />
                        <span>GD Matrix</span>
                    </div>
                </SlotBar>
            </div>
        '));
        then(() -> expectBar(true));
        then(() -> st.inset = false);
        then(() -> expectBar(false));
        then(() -> st.inset = true);
        then(() -> expectBar(true));
        then(() -> st.inset = false);
        then(() -> expectBar(false));
        then(() -> st.inset = true);
        then(() -> expectBar(true));
        then(finishCase);

    }

    static function expectBar(inset:Bool) {

        check('one title', count('.title') == 1, count('.title'));
        check('one icon', count('.icon-sparkles') == 1, count('.icon-sparkles'));
        check('title text', text('.title span') == 'GD Matrix', text('.title span'));
        check('spacer iff inset', count('.spacer') == (inset ? 1 : 0), count('.spacer'));
        final bar = container.querySelector('.bar');
        check('bar child count', bar.children.length == (inset ? 2 : 1), bar.children.length);
        if (inset) {
            check('spacer first', bar.children[0].classList.contains('spacer'), bar.children[0].className);
            check('title second', bar.children[1].classList.contains('title'), bar.children[1].className);
        }
        else {
            check('title only', bar.children[0].classList.contains('title'), bar.children[0].className);
        }

    }

    /** `$children` with no sibling at all: the identity guard path. */
    static function case2_slotAlone() {

        then(() -> start('2 slot alone', () -> '<>
            <div class="root">
                <Plain>
                    <div class="title">Alone</div>
                </Plain>
            </div>
        '));
        then(() -> check('one title', count('.title') == 1, count('.title')));
        then(() -> st.tick++);
        then(() -> {
            check('one title after re-render', count('.title') == 1, count('.title'));
            check('tick applied', container.querySelector('.plain').getAttribute('data-tick') == '1', container.querySelector('.plain').getAttribute('data-tick'));
            check('text intact', text('.title') == 'Alone', text('.title'));
        });
        then(() -> st.tick++);
        then(() -> check('one title after second re-render', count('.title') == 1, count('.title')));
        then(finishCase);

    }

    /** A component as the slot's direct child, the shape wisdom-app uses. */
    static function case3_componentChildNextToConditionalSibling() {

        then(() -> start('3 component child next to a conditional sibling', () -> '<>
            <div class="root">
                <SlotBar>
                    <TopBar />
                </SlotBar>
            </div>
        '));
        then(() -> TopBar.last.n = 5);
        then(() -> check('state applied', text('.topbar') == 'Top 5', text('.topbar')));
        then(() -> st.inset = false);
        then(() -> {
            check('one topbar', count('.topbar') == 1, count('.topbar'));
            check('no spacer', count('.spacer') == 0, count('.spacer'));
            check('state kept', text('.topbar') == 'Top 5', text('.topbar'));
        });
        then(() -> st.inset = true);
        then(() -> {
            check('one topbar back', count('.topbar') == 1, count('.topbar'));
            check('spacer back', count('.spacer') == 1, count('.spacer'));
            check('state kept back', text('.topbar') == 'Top 5', text('.topbar'));
        });
        then(() -> TopBar.last.n = 6);
        then(() -> check('component still live', text('.topbar') == 'Top 6', text('.topbar')));
        then(finishCase);

    }

    /**
     * A stateful component nested inside raw children. It re-renders on its
     * own first, then the slot owner re-renders. The slot owner must emit the
     * nested component's CURRENT root, not the one captured when the parent
     * rendered, or the DOM would be patched back to stale content.
     */
    static function case4_nestedStatefulComponentInRawChildren() {

        then(() -> start('4 nested stateful component in raw children', () -> '<>
            <div class="root">
                <SlotBar>
                    <div class="wrap">
                        <Counter label="solo" />
                    </div>
                </SlotBar>
            </div>
        '));
        then(() -> Counter.last.count = 3);
        then(() -> check('nested state applied', text('.counter') == 'Count: 3', text('.counter')));
        // Re-render of the slot owner with no structural change around the slot.
        then(() -> st.tick++);
        then(() -> {
            check('one counter', count('.counter') == 1, count('.counter'));
            check('nested state not reverted', text('.counter') == 'Count: 3', text('.counter'));
        });
        then(() -> Counter.last.count = 4);
        then(() -> check('nested component still live', text('.counter') == 'Count: 4', text('.counter')));
        // Re-render of the slot owner WITH a structural change around the slot.
        then(() -> st.inset = false);
        then(() -> {
            check('one counter after shift', count('.counter') == 1, count('.counter'));
            check('one wrap after shift', count('.wrap') == 1, count('.wrap'));
            check('last content shown after shift', text('.counter') == 'Count: 4', text('.counter'));
        });
        then(() -> st.inset = true);
        then(() -> {
            check('one counter after shift back', count('.counter') == 1, count('.counter'));
            check('spacer first after shift back', container.querySelector('.bar').children[0].classList.contains('spacer'), container.querySelector('.bar').children[0].className);
            check('last content shown after shift back', text('.counter') == 'Count: 4', text('.counter'));
        });
        then(finishCase);

    }

    /** The conditional sibling lives in the PARENT: the parent re-renders. */
    static function case5_parentDrivenConditionalSibling() {

        then(() -> start('5 parent-driven conditional sibling', () -> '<>
            <div class="root">
                <if ${st.flag}>
                    <p class="note">note</p>
                </if>
                <SlotBar>
                    <div class="title">Parent</div>
                </SlotBar>
            </div>
        '));
        then(() -> st.flag = true);
        then(() -> {
            check('note shown', count('.note') == 1, count('.note'));
            check('one title', count('.title') == 1, count('.title'));
            check('one spacer', count('.spacer') == 1, count('.spacer'));
        });
        then(() -> st.inset = false);
        then(() -> {
            check('spacer gone', count('.spacer') == 0, count('.spacer'));
            check('one title still', count('.title') == 1, count('.title'));
        });
        then(() -> st.flag = false);
        then(() -> {
            check('note gone', count('.note') == 0, count('.note'));
            check('one title still after parent re-render', count('.title') == 1, count('.title'));
            check('spacer still gone', count('.spacer') == 0, count('.spacer'));
        });
        then(() -> st.inset = true);
        then(() -> {
            check('spacer back', count('.spacer') == 1, count('.spacer'));
            check('one title at the end', count('.title') == 1, count('.title'));
        });
        then(finishCase);

    }

    /** Wrapper-override pattern: a component rendering only another component. */
    static function case6_wrapperForwardingSlot() {

        then(() -> start('6 wrapper forwarding its slot', () -> '<>
            <div class="root">
                <Wrapper>
                    <div class="title">Wrapped</div>
                </Wrapper>
            </div>
        '));
        then(() -> check('one title', count('.title') == 1, count('.title')));
        then(() -> st.inset = false);
        then(() -> {
            check('one title without spacer', count('.title') == 1, count('.title'));
            check('no spacer', count('.spacer') == 0, count('.spacer'));
        });
        then(() -> st.inset = true);
        then(() -> {
            check('one title with spacer', count('.title') == 1, count('.title'));
            check('spacer back', count('.spacer') == 1, count('.spacer'));
            check('text intact', text('.title') == 'Wrapped', text('.title'));
        });
        then(finishCase);

    }

    /** Keyed list whose items pass children to a component, then reordered. */
    static function case7_keyedListPassingChildren() {

        then(() -> start('7 keyed list passing children', () -> '<>
            <div class="root">
                <foreach ${st.items} ${(i:Int, item:String) -> '<>
                    <key $item />
                    <SlotBar>
                        <div class="title">$item</div>
                        <Counter label=$item />
                    </SlotBar>
                '} />
            </div>
        '));
        then(() -> Counter.byLabel.get('b').count = 3);
        then(() -> {
            check('three titles', count('.title') == 3, count('.title'));
            check('b counted', text('.counter[data-label="b"]') == 'Count: 3', text('.counter[data-label="b"]'));
        });
        then(() -> st.items = ['c', 'a', 'b']);
        then(() -> {
            check('three titles after reorder', count('.title') == 3, count('.title'));
            check('three spacers after reorder', count('.spacer') == 3, count('.spacer'));
            check('order c a b', titles() == 'c,a,b', titles());
            check('b state kept by key', text('.counter[data-label="b"]') == 'Count: 3', text('.counter[data-label="b"]'));
            check('a state untouched', text('.counter[data-label="a"]') == 'Count: 0', text('.counter[data-label="a"]'));
        });
        then(() -> st.inset = false);
        then(() -> {
            check('no spacers', count('.spacer') == 0, count('.spacer'));
            check('three titles without spacers', count('.title') == 3, count('.title'));
            check('order kept', titles() == 'c,a,b', titles());
        });
        then(finishCase);

    }

    /** A component declaring @props, used with no attribute at all. */
    static function case8_componentWithoutAttributes() {

        then(() -> start('8 component without attributes', () -> '<>
            <div class="root">
                <Icon />
                <Counter />
            </div>
        '));
        then(() -> {
            check('icon default kind', count('.icon-circle') == 1, count('.icon-circle'));
            check('counter rendered', text('.counter') == 'Count: 0', text('.counter'));
            check('counter default label', container.querySelector('.counter').getAttribute('data-label') == '', container.querySelector('.counter').getAttribute('data-label'));
            check('instance registered', Counter.last != null, Counter.last);
        });
        then(() -> Counter.last.count = 2);
        then(() -> check('counter live', text('.counter') == 'Count: 2', text('.counter')));
        then(finishCase);

    }

    /**
     * A stateful component nested in raw children keeps its instance when a
     * structural change around the slot pairs its keyless ancestor with a
     * different sibling. The root is created in its new place and removed
     * from the old one within the same patch, which must not destroy it.
     */
    static function case9_nestedComponentSurvivesStructuralShift() {

        var instance:Counter = null;
        then(() -> start('9 nested component survives a structural shift', () -> '<>
            <div class="root">
                <SlotBar>
                    <div class="wrap">
                        <Counter label="nested" />
                    </div>
                </SlotBar>
            </div>
        '));
        then(() -> { instance = Counter.last; instance.count = 3; });
        then(() -> check('state applied', text('.counter') == 'Count: 3', text('.counter')));
        then(() -> st.inset = false);
        then(() -> {
            check('one counter after shift', count('.counter') == 1, count('.counter'));
            check('same instance after shift', Counter.last == instance, Counter.last == instance);
        });
        then(() -> instance.count = 5);
        then(() -> check('instance live after shift', text('.counter') == 'Count: 5', text('.counter')));
        then(() -> st.inset = true);
        then(() -> {
            check('one counter after shift back', count('.counter') == 1, count('.counter'));
            check('spacer first after shift back', container.querySelector('.bar').children[0].classList.contains('spacer'), container.querySelector('.bar').children[0].className);
        });
        then(() -> instance.count = 6);
        then(() -> check('instance live after shift back', text('.counter') == 'Count: 6', text('.counter')));
        then(finishCase);

    }

    /**
     * Hiding the slot removes its children from the tree, and a component
     * that is no longer in the tree is destroyed, as it would be under any
     * `<if>`. Showing the slot again must not duplicate anything nor throw.
     */
    static function case10_hiddenSlotDestroysItsComponents() {

        var instance:Counter = null;
        then(() -> start('10 hidden slot destroys its components', () -> '<>
            <div class="root">
                <Hider>
                    <div class="wrap">
                        <Counter label="hidden" />
                    </div>
                </Hider>
            </div>
        '));
        then(() -> check('hidden at first', count('.counter') == 0, count('.counter')));
        then(() -> st.flag = true);
        then(() -> {
            check('shown', count('.counter') == 1, count('.counter'));
            instance = Counter.last;
            instance.count = 3;
        });
        then(() -> check('state applied', text('.counter') == 'Count: 3', text('.counter')));
        then(() -> st.flag = false);
        then(() -> {
            check('hidden again', count('.counter') == 0, count('.counter'));
            check('component destroyed', @:privateAccess ctx.components.exists(instance.xid) == false, @:privateAccess ctx.components.exists(instance.xid));
        });
        then(() -> st.flag = true);
        then(() -> {
            check('shown again, once', count('.counter') == 1, count('.counter'));
            check('one wrap', count('.wrap') == 1, count('.wrap'));
        });
        then(finishCase);

    }

    static function titles():String {
        return [for (el in container.querySelectorAll('.title')) (cast el:Element).textContent.trim()].join(',');
    }

    /// Harness

    static function start(name:String, render:() -> VNode) {

        caseName = name;
        st = new State();
        Counter.last = null;
        Counter.byLabel = new Map();
        TopBar.last = null;

        container = document.createDivElement();
        document.body.appendChild(container);

        wisdom = new Wisdom([
            ClassModule.module(), StyleModule.module(), PropsModule.module(), AttributesModule.module(), ListenersModule.module()
        ], new HtmlBackend());

        ctx = wisdom.reactive(container, render);

    }

    static function finishCase() {

        ctx.destroy();
        container.remove();
        js.Syntax.code('console.log({0})', '  done ' + caseName);

    }

    static function then(f:() -> Void) {
        steps.push(f);
    }

    /**
     * One step per turn of the event loop. tracker flushes its autoruns in a
     * microtask, so by the time the next step runs the DOM reflects the
     * previous step's changes.
     */
    static function runSteps() {

        if (steps.length == 0) {
            finish();
            return;
        }
        final f = steps.shift();
        try {
            f();
        }
        catch (e:Dynamic) {
            failures++;
            js.Syntax.code('console.log({0})', 'FAIL [' + caseName + '] exception: ' + Std.string(e));
        }
        haxe.Timer.delay(runSteps, 0);

    }

    static function finish() {

        js.Syntax.code('console.log({0})', failures == 0 ? 'ALL PASS' : failures + ' FAILURE(S)');
        js.Syntax.code('process.exit({0})', failures == 0 ? 0 : 1);

    }

    static function check(what:String, ok:Bool, got:Dynamic) {

        if (ok) {
            js.Syntax.code('console.log({0})', 'PASS [' + caseName + '] ' + what);
        }
        else {
            failures++;
            js.Syntax.code('console.log({0})', 'FAIL [' + caseName + '] ' + what + ' (got ' + Std.string(got) + ')');
        }

    }

    static function count(sel:String):Int {
        return container.querySelectorAll(sel).length;
    }

    static function text(sel:String):String {
        final el = container.querySelector(sel);
        return el == null ? null : el.textContent.trim();
    }

}
