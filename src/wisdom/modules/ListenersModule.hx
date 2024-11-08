package wisdom.modules;

class ListenersModule {

    public static function module():Module {

        return {
            create: updateListeners,
            update: updateListeners,
            destroy: destroyListeners
        };

    }

    static function updateListeners(wisdom:Wisdom, oldVnode:VNode, vnode:VNode):Void {

        final oldOn = oldVnode.data.on;
        final oldElm:Element = cast oldVnode.elm;
        final on = vnode?.data.on;
        final elm:Element = cast vnode?.elm;

        // optimization for reused immutable handlers
        if (oldOn == on) {
            return;
        }

        if (oldOn != null) {
            for (event => oldListener in oldOn) {
                if (oldListener != null && (on == null || !on.exists(event) || on.get(event) != oldListener)) {
                    wisdom.backend.removeEventListener(oldElm, event, oldListener);
                }
            }
        }
        if (on != null) {
            for (event => listener in on) {
                if (listener != null && (oldOn == null || !oldOn.exists(event) || oldOn.get(event) != listener)) {
                    wisdom.backend.addEventListener(elm, event, listener);
                }
            }
        }

    }

    static function destroyListeners(wisdom:Wisdom, oldVnode:VNode):Void {

        updateListeners(wisdom, oldVnode, null);

    }

}
