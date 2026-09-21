package;

import js.Browser.document;
import js.html.Element;
import tracker.Observable;
import ui.GoldenLayout;
import ui.Panel;
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

    /** Read by the root render of the lifecycle case: hides a component. */
    @observe public var flag2:Bool = false;

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

/** Lifecycle log, shared by the lifecycle cases. */
class Life extends Component {

    public static var log:Array<String> = [];

    @props var tag:String = 'life';

    /** When true, the root selector follows `flag` so that a re-render re-creates the root. */
    @props var swap:Bool = false;

    function render() {
        return (swap && Main.st.flag) ? '<><section class="life">$tag</section>' : '<><div class="life">$tag</div>';
    }

    override function didMount(elm:Any) {
        final el:js.html.Element = elm;
        log.push('mount:' + tag + ':' + el.tagName.toLowerCase() + ':' + (document.body.contains(el) ? 'attached' : 'detached'));
    }

    override function willUnmount() {
        log.push('unmount:' + tag);
    }

    override function destroy() {
        log.push('destroy:' + tag);
        super.destroy();
    }

}

/** Wrapper-override: renders only another component. */
class LifeWrapper extends Component {

    function render() '<>
        <Life tag="inner" />
    ';

    override function didMount(elm:Any) {
        Life.log.push('mount:wrapper');
    }

    override function willUnmount() {
        Life.log.push('unmount:wrapper');
    }

}

typedef DockHost = { id:String, element:Element };

/**
 * Stand-in for a docking library such as Golden Layout: it owns the DOM under
 * `root`, creates one content element per panel, hands it to the app through
 * onBind, moves items around on its own, and tears everything down on destroy.
 */
class FakeDock {

    public var root:Element;

    public var hosts:Map<String, Element> = new Map();

    public var items:Map<String, Element> = new Map();

    public var onBind:(id:String, host:Element)->Void = null;

    public var onUnbind:(id:String)->Void = null;

    public var destroyedCount:Int = 0;

    public function new(root:Element) {
        this.root = root;
    }

    public function load(ids:Array<String>) {
        final stack = document.createDivElement();
        stack.className = 'stack';
        root.appendChild(stack);
        for (id in ids) bind(stack, id);
    }

    function bind(stack:Element, id:String) {
        final item = document.createDivElement();
        item.className = 'item';
        final host = document.createDivElement();
        host.className = 'content';
        item.appendChild(host);
        stack.appendChild(item);
        items.set(id, item);
        hosts.set(id, host);
        if (onBind != null) onBind(id, host);
    }

    /** Third-party DOM move: same host element, new place. */
    public function moveToNewStack(id:String) {
        final stack = document.createDivElement();
        stack.className = 'stack';
        root.appendChild(stack);
        stack.appendChild(items.get(id));
    }

    /** Popout-like: the panel is unbound then bound again with a NEW host element. */
    public function rebind(id:String) {
        if (onUnbind != null) onUnbind(id);
        items.get(id).remove();
        bind(cast root.firstElementChild, id);
    }

    public function close(id:String) {
        if (onUnbind != null) onUnbind(id);
        items.get(id).remove();
        items.remove(id);
        hosts.remove(id);
    }

    /** Harsh teardown: clears the hosts themselves, like a library wiping its DOM. */
    public function destroy() {
        destroyedCount++;
        for (id in [for (k in hosts.keys()) k]) {
            if (onUnbind != null) onUnbind(id);
            hosts.get(id).innerHTML = '';
        }
        while (root.firstChild != null) root.removeChild(root.firstChild);
        hosts = new Map();
        items = new Map();
    }

}

/** The shape of a GoldenLayout component built on the new primitives. */
class Dock extends Component {

    public static var last:Dock = null;

    public static var mounts:Int = 0;

    public static var unmounts:Int = 0;

    @props var panels:Array<String> = [];

    @observe var hosts:Array<DockHost> = [];

    public var dock:FakeDock = null;

    var root:Element = null;

    var unmounting:Bool = false;

    function init() {
        last = this;
    }

    function render() '<>
        <div class="dock" data-tick=${Main.st.tick}>
            <div class="dock-root" unmanaged ref=$setRoot />
            <foreach $hosts ${(i:Int, host:DockHost) -> '<>
                <key ${host.id} />
                <portal into=${host.element}>${panel(host.id)}</portal>
            '} />
        </div>
    ';

    function setRoot(el:Any) {
        root = el;
    }

    function panel(name:String):VNode {
        if (children == null) return null;
        for (c in children) {
            final rc = c.reactiveComponent;
            if (rc != null && rc.compInstance is Panel && (cast rc.compInstance:Panel).name == name) return c;
        }
        return null;
    }

    override function didMount(elm:Any) {
        mounts++;
        dock = new FakeDock(root);
        // Reassign, never push: tracker observes the field, not the array.
        dock.onBind = (id, el) -> hosts = hosts.filter(h -> h.id != id).concat([{ id: id, element: el }]);
        dock.onUnbind = id -> { if (!unmounting) hosts = hosts.filter(h -> h.id != id); };
        dock.load(panels);
    }

    override function willUnmount() {
        unmounts++;
        unmounting = true;
        dock.destroy();
        dock = null;
    }

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
        case11_unmanagedElementKeepsForeignChildren();
        case12_portalRendersIntoHost();
        case13_componentLifecycle();
        case14_refFollowsTheElement();
        case15_dockIntegration();
        case16_goldenLayout();

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
        // The shift happens BEFORE the nested component ever re-renders on
        // its own, so its root is the very object the parent captured and
        // no stale reference can keep it alive by accident.
        then(() -> instance = Counter.last);
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

    /** An element whose inside belongs to a third party survives re-renders of its attributes. */
    static function case11_unmanagedElementKeepsForeignChildren() {

        var um:Element = null;
        then(() -> start('11 unmanaged element keeps foreign children', () -> '<>
            <div class="root">
                <div class=${'um ' + (st.flag ? 'on' : 'off')} unmanaged />
            </div>
        '));
        then(() -> {
            um = container.querySelector('.um');
            check('unmanaged rendered', um != null, um);
            final foreign = document.createElement('i');
            foreign.className = 'foreign';
            um.appendChild(foreign);
        });
        then(() -> st.flag = true);
        then(() -> {
            check('same element after re-render', container.querySelector('.um') == um, container.querySelector('.um') == um);
            check('class updated', um.classList.contains('on') && !um.classList.contains('off'), um.className);
            check('foreign child kept', um.querySelectorAll('.foreign').length == 1, um.querySelectorAll('.foreign').length);
        });
        then(finishCase);

    }

    /** Children of a portal live in the host, but stay Wisdom children: diffed, stateful, destroyed. */
    static function case12_portalRendersIntoHost() {

        final host = document.createDivElement();
        host.className = 'host';
        var xid:String = null;
        then(() -> {
            document.body.appendChild(host);
            start('12 portal renders into a host element', () -> '<>
                <div class="root">
                    <if ${st.flag}>
                        <portal into=$host>
                            <div class="tp">${st.tick}</div>
                            <Counter label="p" />
                        </portal>
                    </if>
                </div>
            ');
        });
        then(() -> st.flag = true);
        then(() -> {
            check('content in host', host.querySelectorAll('.tp').length == 1, host.querySelectorAll('.tp').length);
            check('content not in container', container.querySelector('.tp') == null, container.querySelector('.tp'));
            check('one placeholder comment', comments(container) == 1, comments(container));
            check('counter in host', host.querySelector('.counter') != null, host.querySelector('.counter'));
            xid = Counter.last.xid;
        });
        then(() -> Counter.last.count = 2);
        then(() -> check('counter state applied', host.querySelector('.counter').textContent.trim() == 'Count: 2', host.querySelector('.counter').textContent));
        then(() -> st.tick++);
        then(() -> {
            check('text updated in host', host.querySelector('.tp').textContent.trim() == '1', host.querySelector('.tp').textContent);
            check('counter kept across parent re-render', host.querySelector('.counter').textContent.trim() == 'Count: 2', host.querySelector('.counter').textContent);
            check('still one tp', host.querySelectorAll('.tp').length == 1, host.querySelectorAll('.tp').length);
        });
        then(() -> st.flag = false);
        then(() -> {
            check('host emptied', host.childNodes.length == 0, host.childNodes.length);
            check('placeholder removed', comments(container) == 0, comments(container));
            check('counter destroyed', @:privateAccess ctx.components.exists(xid) == false, @:privateAccess ctx.components.exists(xid));
        });
        then(() -> st.flag = true);
        then(() -> {
            check('re-created once', host.querySelectorAll('.tp').length == 1, host.querySelectorAll('.tp').length);
            check('counter fresh', host.querySelector('.counter').textContent.trim() == 'Count: 0', host.querySelector('.counter').textContent);
        });
        then(() -> {
            finishCase();
            host.remove();
        });

    }

    /** didMount / willUnmount / destroy ordering, including the wrapper-override pattern. */
    static function case13_componentLifecycle() {

        then(() -> {
            Life.log = [];
            start('13 component lifecycle', () -> '<>
                <div class="root">
                    <if ${!st.flag2}>
                        <Life tag="a" swap=true />
                    </if>
                    <LifeWrapper />
                </div>
            ');
        });
        then(() -> {
            check('a mounted attached', Life.log.indexOf('mount:a:div:attached') != -1, Life.log.join(' '));
            final inner = Life.log.indexOf('mount:inner:div:attached');
            final wrapper = Life.log.indexOf('mount:wrapper');
            check('inner mounted before wrapper', inner != -1 && wrapper != -1 && inner < wrapper, Life.log.join(' '));
            check('no unmount yet', Life.log.filter(l -> l.startsWith('unmount')).length == 0, Life.log.join(' '));
            Life.log = [];
        });
        then(() -> st.flag = true);
        then(() -> {
            check('root re-created: unmount then mount', Life.log.join(',') == 'unmount:a,mount:a:section:attached', Life.log.join(','));
            Life.log = [];
        });
        then(() -> st.flag2 = true);
        then(() -> {
            check('hidden: unmount then destroy', Life.log.join(',') == 'unmount:a,destroy:a', Life.log.join(','));
            Life.log = [];
        });
        then(() -> {
            finishCase();
            final uw = Life.log.indexOf('unmount:wrapper');
            final ui = Life.log.indexOf('unmount:inner');
            check('wrapper unmounted on context destroy', uw != -1, Life.log.join(' '));
            check('inner unmounted on context destroy', ui != -1, Life.log.join(' '));
            check('wrapper unmounted before inner', uw != -1 && ui != -1 && uw < ui, Life.log.join(' '));
            check('inner destroyed', Life.log.indexOf('destroy:inner') != -1, Life.log.join(' '));
            check('no mount on destroy', Life.log.filter(l -> l.startsWith('mount')).length == 0, Life.log.join(' '));
        });

    }

    static var refLog:Array<String> = [];

    static function onRef(el:Any) {
        refLog.push(el == null ? 'null' : (document.body.contains(el) ? 'attached' : 'detached'));
    }

    /** ref fires with the attached element on creation, with null on destruction, nothing in between. */
    static function case14_refFollowsTheElement() {

        then(() -> {
            refLog = [];
            start('14 ref follows the element', () -> '<>
                <div class="root" data-tick=${st.tick}>
                    <if ${st.flag}>
                        <span class="r" ref=$onRef />
                    </if>
                </div>
            ');
        });
        then(() -> check('nothing before creation', refLog.length == 0, refLog.join(',')));
        then(() -> st.flag = true);
        then(() -> check('attached on creation', refLog.join(',') == 'attached', refLog.join(',')));
        then(() -> st.tick++);
        then(() -> check('silent on re-render', refLog.join(',') == 'attached', refLog.join(',')));
        then(() -> st.flag = false);
        then(() -> check('null on destruction', refLog.join(',') == 'attached,null', refLog.join(',')));
        then(finishCase);

    }

    /**
     * The Golden Layout shape end to end against a fake docking library: panels
     * rendered into hosts created by the library, moved, re-bound, closed, and
     * the whole thing torn down while the library wipes its own DOM.
     */
    static function case15_dockIntegration() {

        var counterXid:String = null;
        var dockRef:FakeDock = null;
        then(() -> {
            Dock.mounts = 0;
            Dock.unmounts = 0;
            Panel.destroyedCount = 0;
            start('15 dock integration', () -> '<>
                <div class="root" data-tick=${st.tick}>
                    <if ${st.flag}>
                        <Dock panels=${['editor', 'console']}>
                            <Panel name="editor"><Counter label="ed" /></Panel>
                            <Panel name="console"><div class="con">Console</div></Panel>
                        </Dock>
                    </if>
                </div>
            ');
        });
        then(() -> st.flag = true);
        then(() -> {
            check('mounted once', Dock.mounts == 1, Dock.mounts);
            final editorHost = Dock.last.dock.hosts.get('editor');
            final consoleHost = Dock.last.dock.hosts.get('console');
            check('editor panel in its host', editorHost.querySelector('.panel[data-panel=editor] .counter') != null, editorHost.innerHTML);
            check('console panel in its host', consoleHost.querySelector('.panel[data-panel=console] .con') != null, consoleHost.innerHTML);
            check('two panels', count('.panel') == 2, count('.panel'));
            check('two placeholders', comments(container.querySelector('.dock')) == 2, comments(container.querySelector('.dock')));
            counterXid = Counter.byLabel.get('ed').xid;
            dockRef = Dock.last.dock;
        });
        then(() -> Counter.byLabel.get('ed').count = 3);
        then(() -> check('counter updated in host', text('.counter') == 'Count: 3', text('.counter')));
        then(() -> st.tick++);
        then(() -> {
            check('two panels after parent re-render', count('.panel') == 2, count('.panel'));
            check('counter kept after parent re-render', text('.counter') == 'Count: 3', text('.counter'));
            check('two placeholders after parent re-render', comments(container.querySelector('.dock')) == 2, comments(container.querySelector('.dock')));
        });
        then(() -> Dock.last.dock.moveToNewStack('editor'));
        then(() -> Counter.byLabel.get('ed').count = 4);
        then(() -> {
            check('counter live after third-party move', text('.counter') == 'Count: 4', text('.counter'));
            check('two panels after move', count('.panel') == 2, count('.panel'));
        });
        then(() -> Dock.last.dock.rebind('console'));
        then(() -> {
            check('console content once after rebind', count('.con') == 1, count('.con'));
            check('console content in the new host', Dock.last.dock.hosts.get('console').querySelector('.con') != null, Dock.last.dock.hosts.get('console').innerHTML);
            check('nothing destroyed by rebind', Panel.destroyedCount == 0, Panel.destroyedCount);
        });
        then(() -> Dock.last.dock.close('console'));
        then(() -> {
            check('console content gone', count('.con') == 0, count('.con'));
            check('console panel destroyed', Panel.destroyedCount == 1, Panel.destroyedCount);
            check('one panel left', count('.panel') == 1, count('.panel'));
        });
        then(() -> st.flag = false);
        then(() -> {
            check('unmounted once', Dock.unmounts == 1, Dock.unmounts);
            check('fake dock destroyed', dockRef.destroyedCount == 1, dockRef.destroyedCount);
            check('no panel left', count('.panel') == 0, count('.panel'));
            check('counter destroyed', @:privateAccess ctx.components.exists(counterXid) == false, @:privateAccess ctx.components.exists(counterXid));
            check('editor panel destroyed', Panel.destroyedCount == 2, Panel.destroyedCount);
        });
        then(() -> st.flag = true);
        then(() -> {
            check('mounted again', Dock.mounts == 2, Dock.mounts);
            check('two panels again', count('.panel') == 2, count('.panel'));
            check('fresh counter', text('.counter') == 'Count: 0', text('.counter'));
        });
        then(finishCase);

    }

    /** Golden Layout config for case 16: `notes` is deliberately not part of it. */
    static final GL_CONFIG:Dynamic = {
        root: {
            type: 'row',
            content: [
                { type: 'component', componentType: 'editor', title: 'Editor' },
                { type: 'component', componentType: 'console', title: 'Console' }
            ]
        }
    };

    /**
     * The real Golden Layout, end to end: panels rendered into the containers
     * it creates, a parent re-render, a panel opened and one closed through
     * its API, then the whole layout unmounted and mounted again.
     */
    static function case16_goldenLayout() {

        var counterXid:String = null;
        then(() -> {
            GoldenLayout.mounts = 0;
            GoldenLayout.unmounts = 0;
            Panel.destroyedCount = 0;
            start('16 golden layout', () -> '<>
                <div class="root" data-tick=${st.tick}>
                    <if ${st.flag}>
                        <GoldenLayout config=$GL_CONFIG>
                            <Panel name="editor"><Counter label="gl" /></Panel>
                            <Panel name="console"><div class="con">Console</div></Panel>
                            <Panel name="notes"><div class="notes">Notes</div></Panel>
                        </GoldenLayout>
                    </if>
                </div>
            ');
        });
        then(() -> st.flag = true);
        // stackCreated reaches the layout manager on the next animation frame.
        thenWait(50);
        then(() -> {
            check('mounted once', GoldenLayout.mounts == 1, GoldenLayout.mounts);
            check('two containers', count('.lm_content') == 2, count('.lm_content'));
            check('editor panel in a container', container.querySelector('.lm_content .panel[data-panel=editor] .counter') != null, container.innerHTML);
            check('console panel in a container', container.querySelector('.lm_content .panel[data-panel=console] .con') != null, container.innerHTML);
            check('notes not rendered', count('.notes') == 0, count('.notes'));
            var allInContainers = true;
            for (panel in container.querySelectorAll('.panel')) {
                if ((cast panel:Element).closest('.lm_content') == null) allInContainers = false;
            }
            check('every panel inside a container', allInContainers, allInContainers);
            check('two stacks created', GoldenLayout.last.stacksCreated == 2, GoldenLayout.last.stacksCreated);
            check('header button per stack', count('.lm_controls .gl-add') == 2, count('.lm_controls .gl-add'));
            counterXid = Counter.byLabel.get('gl').xid;
        });
        then(() -> Counter.byLabel.get('gl').count = 3);
        then(() -> check('counter updated in container', text('.counter') == 'Count: 3', text('.counter')));
        then(() -> st.tick++);
        then(() -> {
            check('two containers after parent re-render', count('.lm_content') == 2, count('.lm_content'));
            check('two panels after parent re-render', count('.panel') == 2, count('.panel'));
            check('counter kept after parent re-render', text('.counter') == 'Count: 3', text('.counter'));
        });
        then(() -> GoldenLayout.last.open('notes', 'Notes'));
        then(() -> {
            check('three containers after open', count('.lm_content') == 3, count('.lm_content'));
            check('notes rendered in a container', container.querySelector('.lm_content .notes') != null, count('.notes'));
        });
        then(() -> GoldenLayout.last.close('console'));
        then(() -> {
            check('console content gone', count('.con') == 0, count('.con'));
            check('console panel destroyed', Panel.destroyedCount == 1, Panel.destroyedCount);
            check('two containers after close', count('.lm_content') == 2, count('.lm_content'));
        });
        then(() -> {
            final saved = GoldenLayout.last.gl.saveLayout();
            check('layout saved', saved != null && saved.root != null, saved);
        });
        then(() -> st.flag = false);
        then(() -> {
            check('unmounted once', GoldenLayout.unmounts == 1, GoldenLayout.unmounts);
            check('layout dom gone', count('.lm_goldenlayout') == 0, count('.lm_goldenlayout'));
            check('no panel left', count('.panel') == 0, count('.panel'));
            check('remaining panels destroyed', Panel.destroyedCount == 3, Panel.destroyedCount);
            check('counter destroyed', @:privateAccess ctx.components.exists(counterXid) == false, @:privateAccess ctx.components.exists(counterXid));
        });
        then(() -> st.flag = true);
        thenWait(50);
        then(() -> {
            check('mounted again', GoldenLayout.mounts == 2, GoldenLayout.mounts);
            check('two containers again', count('.lm_content') == 2, count('.lm_content'));
            check('fresh counter', text('.counter') == 'Count: 0', text('.counter'));
        });
        then(finishCase);

    }

    static function comments(el:Element):Int {
        if (el == null) return -1;
        var n = 0;
        for (i in 0...el.childNodes.length) {
            if (el.childNodes[i].nodeType == 8) n++;
        }
        return n;
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

    static var nextDelay:Int = 0;

    /** Waits `ms` before the next step, for third parties that defer work to a frame. */
    static function thenWait(ms:Int) {
        then(() -> nextDelay = ms);
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
        final delay = nextDelay;
        nextDelay = 0;
        haxe.Timer.delay(runSteps, delay);

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
