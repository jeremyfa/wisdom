package wisdom;

#if tracker

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
#else
import haxe.Int64;
import tracker.Autorun;
#end

class Reactive {

    #if !macro

    static var renderReactiveComponentDyn:Dynamic = null;

    @:allow(wisdom.ReactiveComponent)
    static var currentReactiveContext:ReactiveContext = null;

    public static function reactive(wisdom:Wisdom, container:Any, render:()-> #if completion Any #else VNode #end):ReactiveContext {

        if (renderReactiveComponentDyn == null) {
            renderReactiveComponentDyn = renderReactiveComponent;
        }

        final _prevBaseXid = Wisdom.baseXid;
        Wisdom.baseXid = null;

        final _prevRenderComponent = Wisdom.renderComponent;
        Wisdom.renderComponent = renderReactiveComponentDyn;

        final _prevReactiveContext = Reactive.currentReactiveContext;
        final reactiveContext = new ReactiveContext(wisdom, container);
        Reactive.currentReactiveContext = reactiveContext;

        wisdom.addModule(reactiveContext.hooks);

        var renderedAny:Any = null;

        reactiveContext.autorun = new Autorun(() -> {

            var autorunPrevBaseXid = Wisdom.baseXid;
            Wisdom.baseXid = null;

            var autorunPrevRenderComponent = Wisdom.renderComponent;
            Wisdom.renderComponent = renderReactiveComponentDyn;

            var autorunPrevReactiveContext = Reactive.currentReactiveContext;
            Reactive.currentReactiveContext = reactiveContext;

            renderedAny = render();

            Wisdom.baseXid = autorunPrevBaseXid;
            Wisdom.renderComponent = autorunPrevRenderComponent;
            Reactive.currentReactiveContext = autorunPrevReactiveContext;

        },
        () -> {
            reactiveContext.container = wisdom.patch(
                reactiveContext.container,
                renderedAny
            );
        });

        if (renderedAny != null) {
            if (!VNode.isVNode(renderedAny)) {
                throw "The root of a reactive vdom must be a single VNode";
            }
        }
        else {
            reactiveContext.destroy();
        }

        Reactive.currentReactiveContext = _prevReactiveContext;
        Wisdom.renderComponent = _prevRenderComponent;
        Wisdom.baseXid = _prevBaseXid;

        return reactiveContext;

    }

    static function renderReactiveComponent(comp:Any, xid:Xid, data:VNodeData, children:Array<VNode>):Any {

        var reactiveComponent = Reactive.currentReactiveContext.components.get(xid);

        if (reactiveComponent == null) {
            reactiveComponent = new ReactiveComponent(
                xid, comp, data, children,
                Reactive.currentReactiveContext,
                Wisdom.renderComponent
            );
            Reactive.currentReactiveContext.components.set(xid, reactiveComponent);
        }
        else {
            reactiveComponent.update(data, children);
        }

        return reactiveComponent.rendered;

    }

    #end

}

#end
