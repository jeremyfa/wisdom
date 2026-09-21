package ui;

import glext.BindableComponent;
import glext.BubblingEvent;
import glext.ComponentContainer;
import glext.ComponentItem;
import glext.ContentItem;
import glext.Stack;
import js.Browser.document;
import js.html.Element;
import wisdom.Component;
import wisdom.VNode;

typedef PanelHost = { name:String, element:Element };

/**
 * Golden Layout as a Wisdom component. Its children are <Panel name="..."> whose
 * `name` matches a `componentType` of the layout config. GL owns the DOM under
 * the unmanaged root; every panel content is a <portal> into the container
 * element GL hands over in bindComponentEvent, so the panel children stay
 * ordinary Wisdom children (reactive, stateful, destroyed when their tab
 * closes).
 */
class GoldenLayout extends Component {

    public static var last:GoldenLayout = null;

    public static var mounts:Int = 0;

    public static var unmounts:Int = 0;

    /** LayoutConfig (root/content/...), `componentType` = a <Panel> name. */
    @props var config:Dynamic = null;

    @observe var hosts:Array<PanelHost> = [];

    public var gl(default, null):glext.GoldenLayout = null;

    public var stacksCreated(default, null):Int = 0;

    var root:Element = null;

    var unmounting:Bool = false;

    var onStackCreatedBound:Dynamic = null;

    function init() {
        last = this;
    }

    function render() '<>
        <div class="gl-wrap" style=${{ position: 'relative', width: '100%', height: '100%' }}>
            <div class="gl-root" style=${{ position: 'absolute', top: '0', left: '0', right: '0', bottom: '0' }} unmanaged ref=$setRoot />
            <foreach $hosts ${(i:Int, host:PanelHost) -> '<>
                <key ${host.name} />
                <portal into=${host.element}>${panel(host.name)}</portal>
            '} />
        </div>
    ';

    function setRoot(el:Any) {
        root = el;
    }

    /** The child <Panel> root for `name`, found through its component instance. */
    function panel(name:String):VNode {
        if (children == null) return null;
        for (child in children) {
            final rc = child.reactiveComponent;
            if (rc != null && rc.compInstance is Panel && (cast rc.compInstance:Panel).name == name) return child;
        }
        return null;
    }

    override function didMount(elm:Any) {
        mounts++;
        gl = new glext.GoldenLayout(root, bind, unbind);
        gl.resizeWithContainerAutomatically = true;
        // `stackCreated` bubbles asynchronously (requestAnimationFrame) as a
        // BubblingEvent; off() needs the very same reference as on().
        onStackCreatedBound = onStackCreated;
        gl.on('stackCreated', onStackCreatedBound);
        gl.loadLayout(config);
    }

    override function willUnmount() {
        unmounts++;
        // GL's destroy() does not unbind the remaining panels, and the portals
        // go away with this component anyway: unbind must not touch `hosts`
        // from here on.
        unmounting = true;
        gl.off('stackCreated', onStackCreatedBound);
        gl.destroy();
        gl = null;
    }

    function bind(container:ComponentContainer, itemConfig:Dynamic):BindableComponent {
        final name:String = itemConfig.componentType;
        // Reassign, never push: tracker observes the field, not the array.
        hosts = hosts.filter(h -> h.name != name).concat([{ name: name, element: container.element }]);
        return { component: name, virtual: false };
    }

    function unbind(container:ComponentContainer):Void {
        if (unmounting) return;
        final element = container.element;
        hosts = hosts.filter(h -> h.element != element);
    }

    function onStackCreated(event:BubblingEvent):Void {
        stacksCreated++;
        final stack:Stack = cast event.origin;
        final controls = stack.header.controlsContainerElement;
        final button = document.createButtonElement();
        button.className = 'gl-add';
        button.textContent = '+';
        controls.insertBefore(button, controls.firstChild);
    }

    /** Opens a panel; a <Panel name=...> child must exist for it. */
    public function open(name:String, title:String):Void {
        gl.addComponentAtLocation(name, null, title);
    }

    public function close(name:String):Void {
        final item = findComponentItem(gl.rootItem, name);
        if (item != null) item.close();
    }

    function findComponentItem(item:ContentItem, name:String):ComponentItem {
        if (item == null) return null;
        if (item.isComponent && (cast item:ComponentItem).componentType == name) return cast item;
        for (child in item.contentItems) {
            final found = findComponentItem(child, name);
            if (found != null) return found;
        }
        return null;
    }

}
