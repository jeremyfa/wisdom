package markup;

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

    @:allow(markup.ReactiveComponent)
    static var currentReactiveContext:ReactiveContext = null;

    public static function reactiveVDom(markup:Markup, container:Any, render:()-> #if completion Any #else VNode #end):ReactiveContext {

        if (renderReactiveComponentDyn == null) {
            renderReactiveComponentDyn = renderReactiveComponent;
        }

        final _prevBaseXid = Markup.baseXid;
        Markup.baseXid = null;

        final _prevRenderComponent = Markup.renderComponent;
        Markup.renderComponent = renderReactiveComponentDyn;

        final _prevReactiveContext = Reactive.currentReactiveContext;
        final reactiveContext = new ReactiveContext(markup, container);
        Reactive.currentReactiveContext = reactiveContext;

        markup.addModule(reactiveContext.hooks);

        var renderedAny:Any = null;

        reactiveContext.autorun = new Autorun(() -> {

            var autorunPrevBaseXid = Markup.baseXid;
            Markup.baseXid = null;

            var autorunPrevRenderComponent = Markup.renderComponent;
            Markup.renderComponent = renderReactiveComponentDyn;

            var autorunPrevReactiveContext = Reactive.currentReactiveContext;
            Reactive.currentReactiveContext = reactiveContext;

            renderedAny = render();

            Markup.baseXid = autorunPrevBaseXid;
            Markup.renderComponent = autorunPrevRenderComponent;
            Reactive.currentReactiveContext = autorunPrevReactiveContext;

        },
        () -> {
            reactiveContext.container = markup.patch(
                reactiveContext.container,
                renderedAny
            );
        });

        if (renderedAny != null) {
            if (!(renderedAny is VNode)) {
                throw "The root of a reactive vdom must be a single VNode";
            }
        }
        else {
            reactiveContext.destroy();
        }

        Reactive.currentReactiveContext = _prevReactiveContext;
        Markup.renderComponent = _prevRenderComponent;
        Markup.baseXid = _prevBaseXid;

        return reactiveContext;

    }

    static function renderReactiveComponent(comp:(xid:Xid, ctx:ReactiveContext, data:VNodeData, children:Array<VNode>)->Any, xid:Xid, data:VNodeData, children:Array<VNode>):Any {

        var reactiveComponent = Reactive.currentReactiveContext.components.get(xid);

        if (reactiveComponent == null) {
            reactiveComponent = new ReactiveComponent(
                xid, comp, data, children,
                Reactive.currentReactiveContext,
                Markup.renderComponent
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
