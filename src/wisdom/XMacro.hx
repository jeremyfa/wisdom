package wisdom;

#if macro
import haxe.macro.Compiler;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.PositionTools;

using StringTools;

class XMacro {

    // A flag used to prevent the compiler to perform multiple times
    // expensive operations when an error happens
    static var macroHasErrors:Bool = false;

    macro static public function makePropsObservable():Void {

        #if tracker
        tracker.macros.ObservableMacro.addObservableMeta('props');
        #end

    }

    macro static public function build():Array<Field> {

        var fields = Context.getBuildFields();

        for (field in fields) {

            switch field.kind {
                case FVar(t, e):
                    if (e != null)
                        field.kind = FVar(t, processInlineMarkup(e));

                case FProp(get, set, t, e):
                    if (e != null)
                        field.kind = FProp(get, set, t, processInlineMarkup(e));

                case FFun(f):
                    var stateFields:Map<String,FunctionArg> = null;
                    if (hasXMeta(field.meta)) {
                        stateFields = transformWisdomComponent(field);
                    }
                    f.expr = processInlineMarkup(f.expr);

                    #if !(completion || display)
                    if (stateFields != null) {
                        f.expr = processStateFields(f.expr, stateFields);
                    }
                    #end

            }

        }

        return fields;

    }

    static function hasXMeta(meta:Metadata):Bool {

        if (meta == null || meta.length == 0) return false;

        for (meta in meta) {
            if (meta.name == 'x') {
                return true;
            }
        }

        return false;

    }

    static function hasStateMeta(meta:Metadata):Bool {

        if (meta == null || meta.length == 0) return false;

        for (meta in meta) {
            if (meta.name == 'state') {
                return true;
            }
        }

        return false;

    }

    static function transformWisdomComponent(field:Field):Map<String,FunctionArg> {

        var stateFields:Map<String,FunctionArg> = null;

        switch field.kind {
            case FVar(t, e):
            case FProp(get, set, t, e):

            case FFun(fn):

                #if !(completion || display)
                // Convert arguments
                var rawArgs = fn.args;
                fn.args = [{
                    name: 'xid_',
                    type: macro :wisdom_.Xid
                },
                {
                    name: 'ctx_',
                    type: macro :wisdom_.ReactiveContext
                },
                {
                    name: 'data_',
                    type: macro :wisdom_.VNodeData
                },
                {
                    name: 'children',
                    type: macro :Array<wisdom_.VNode>
                }];
                #end

                // Add return if needed
                switch (fn.expr.expr) {
                    case EBlock(exprs) if (exprs.length == 1):
                        switch (exprs[0].expr) {
                            case EConst(CString(_, _)):
                                exprs[0].expr = EReturn({
                                    pos: exprs[0].pos,
                                    expr: exprs[0].expr
                                });
                            default:
                        }
                    case EConst(CString(_, _)):
                        fn.expr.expr = EReturn({
                            pos: fn.expr.pos,
                            expr: fn.expr.expr
                        });
                    default:
                }

                // Ensure expr is surrounded with a block
                switch (fn.expr.expr) {
                    case EBlock(exprs):
                    default:
                        fn.expr.expr = EBlock([{
                            pos: fn.expr.pos,
                            expr: fn.expr.expr
                        }]);
                }

                #if !(completion || display)

                var printer = new haxe.macro.Printer();

                // Add arguments destructuration
                var argExprs = [];
                for (i in 0...rawArgs.length) {
                    var arg = rawArgs[i];
                    var argNameRaw = arg.name;
                    var argName = argNameRaw;
                    var argType = arg.type != null ? printer.printComplexType(arg.type) : 'Dynamic';
                    while (argName.startsWith('_')) argName = argName.substr(1);
                    switch (argName) {
                        case 'children':
                            // Nothing to do here
                        case 'props' | 'attrs' | 'classes' | 'style' | 'on':
                            argExprs.push(
                                Context.parse('var ${argNameRaw}:${argType} = data_.${argName}', field.pos)
                            );
                        case _ if (hasStateMeta(arg.meta)):
                            if (stateFields == null) stateFields = new Map();
                            stateFields.set(argName, arg);
                        case _:
                            argExprs.push(
                                Context.parse('var ${argNameRaw}:${argType} = data_.props.get("' + argName + '")', field.pos)
                            );
                    }
                }

                if (stateFields != null) {

                    var printer = new haxe.macro.Printer();

                    var initState = [];
                    initState.push('if (state_ == null) {');
                    initState.push('    state_ = ctx_.initState(xid_);');
                    for (name => arg in stateFields) {
                        if (arg.value != null) {
                            var typeStr = ComplexTypeTools.toString(arg.type);
                            initState.push('    final state_def_${name}_:$typeStr = ${printer.printExpr(arg.value)};');
                            initState.push('    state_.set("${name}", state_def_${name}_);');
                        }
                    }
                    initState.push('}');

                    switch (fn.expr.expr) {
                        case EBlock(exprs):
                            fn.expr.expr = EBlock([Context.parse(initState.join('\n'), field.pos)].concat(exprs));
                        default:
                    }

                    switch (fn.expr.expr) {
                        case EBlock(exprs):
                            fn.expr.expr = EBlock([Context.parse('var state_ = ctx_.getState(xid_)', field.pos)].concat(exprs));
                        default:
                    }

                    fn.expr = processStateFields(fn.expr, stateFields);
                }

                switch (fn.expr.expr) {
                    case EBlock(exprs):
                        fn.expr.expr = EBlock(argExprs.concat(exprs));
                    default:
                }

                #end
        }

        return stateFields;

    }

    static function processStateFields(e:Expr, stateFields:Map<String,FunctionArg>, observe:Bool = true, ?consumed:Map<Expr,Bool>):Expr {

        // TODO stop on shadowed state variables

        if (e == null) return null;

        if (consumed == null) consumed = new Map();
        if (consumed.exists(e)) return e;
        consumed.set(e, true);

        switch e.expr {
            case EConst(CIdent(s)) if (stateFields.exists(s)):
                if (observe) {
                    var expr = macro @:pos(e.pos) state_.get($v{s});
                    return {
                        expr: EParenthesis({
                            expr: ECheckType(expr, stateFields.get(s).type),
                            pos: e.pos
                        }),
                        pos: e.pos
                    }
                }
                else {
                    var expr = macro @:pos(e.pos) state_.getUnobserved($v{s});
                    return {
                        expr: EParenthesis({
                            expr: ECheckType(expr, stateFields.get(s).type),
                            pos: e.pos
                        }),
                        pos: e.pos
                    }
                }

            case EBinop(op, e1, e2):
                switch op {
                    case OpAssignOp(op):
                        switch e1.expr {
                            case EConst(CIdent(s)) if (stateFields.exists(s)):
                                final expr = {
                                    expr: EBinop(op, processStateFields(e1, stateFields, true, consumed), processStateFields(e2, stateFields, true, consumed)),
                                    pos: e.pos
                                };
                                return macro state_.set($v{s}, $expr);

                            case _:
                        }

                    case OpAssign:
                        switch e1.expr {
                            case EConst(CIdent(s)) if (stateFields.exists(s)):
                                final expr = processStateFields(e2, stateFields, true, consumed);
                                return macro state_.set($v{s}, $expr);

                            case _:
                        }

                    case _:
                }

            case EUnop(op, postFix, e1):
                switch e1.expr {
                    case EConst(CIdent(s)) if (stateFields.exists(s)):
                        switch [op, postFix] {

                            case [OpIncrement, true]:
                                final expr = {
                                    expr: EBinop(OpAdd, processStateFields(e1, stateFields, false, consumed), macro 1),
                                    pos: e.pos
                                };
                                return macro state_.getUnobservedAndSet($v{s}, $expr);

                            case [OpDecrement, true]:
                                final expr = {
                                    expr: EBinop(OpSub, processStateFields(e1, stateFields, false, consumed), macro 1),
                                    pos: e.pos
                                };
                                return macro state_.getUnobservedAndSet($v{s}, $expr);

                            case [OpIncrement, false]:
                                final expr = {
                                    expr: EBinop(OpAdd, processStateFields(e1, stateFields, false, consumed), macro 1),
                                    pos: e.pos
                                };
                                return macro state_.set($v{s}, $expr);

                            case [OpDecrement, false]:
                                final expr = {
                                    expr: EBinop(OpSub, processStateFields(e1, stateFields, false, consumed), macro 1),
                                    pos: e.pos
                                };
                                return macro state_.set($v{s}, $expr);

                            case [_, _]:
                                final expr = {
                                    expr: EUnop(op, postFix, processStateFields(e1, stateFields, true, consumed)),
                                    pos: e.pos
                                };
                                return macro state_.set($v{s}, $expr);
                        }

                    case _:
                }

            case _:
        }

        return ExprTools.map(e, e -> {
            try {
                return processStateFields(e, stateFields, true, consumed);
            }
            catch (err:Any) {
                // Why is this happening when using haxe completion server?
                trace('Exception of type: ' + Type.getClass(err));
                if (Std.string(err) != 'Stack overflow') {
                    throw err;
                }
            }
            return e;
        });

    }

    static function processInlineMarkup(e:Expr, ?consumed:Map<Expr,Bool>):Expr {

        if (e == null) return null;

        if (consumed == null) consumed = new Map();
        if (consumed.exists(e)) return e;
        consumed.set(e, true);

        switch e.expr {
            case EMeta(s, expr) if (s.name == ':wisdom'):
                switch expr.expr {
                    case EConst(CString(s, kind)):
                        final expr = processMarkupString(s, kind, e.pos);
                        return macro $expr;
                    case _:
                }
            case EConst(CString(s, kind)) if (s.startsWith("<>") && kind == SingleQuotes):
                final expr = processMarkupString(s, kind, e.pos);
                return macro $expr;
            case EDisplay(expr, displayKind):
                return e;
            case _:
        }

        return ExprTools.map(e, e -> {
            try {
                return processInlineMarkup(e, consumed);
            }
            catch (err:Any) {
                // Why is this happening when using haxe completion server?
                trace('Exception of type: ' + Type.getClass(err));
                if (Std.string(err) != 'Stack overflow') {
                    throw err;
                }
            }
            return e;
        });

    }

    static function processMarkupString(s:String, kind:StringLiteralKind, pos:Position):Expr {
        if (!macroHasErrors) {
            final markup2vdom = new MarkupToVDom();
            final offset = s.startsWith("<>") ? 2 : 0;
            try {
                var res = markup2vdom.convert(offset > 0 ? s.substr(offset) : s);
                #if !(completion || display)
                res = '{wisdom_.Wisdom.begin(); final vdom_ = $res; wisdom_.Wisdom.end(); vdom_;}';
                #end
                #if wisdom_print_vnode_haxe
                @:privateAccess if (markup2vdom.output != null) {
                    trace(markup2vdom.output.toString());
                }
                #end
                for (i in markup2vdom.componentTagPos) {
                    s = s.substring(0, i + offset) + "$" + s.substring(i + offset + 1);
                }
                #if !(completion || display)
                return Context.parse(res, pos);
                #end
            }
            catch (e:MarkupToVDom.MarkupToVDomError) {
                @:privateAccess if (markup2vdom.output != null) {
                    trace(markup2vdom.output.toString());
                }
                macroHasErrors = true;
                final posInfos = PositionTools.getInfos(pos);
                Context.error(
                    e.message + (e.pos != -1 ? ' at position ${e.pos}' : ''),
                    e.pos != -1 ? PositionTools.make({
                        min: posInfos.min + 1 + e.pos + offset,
                        max: posInfos.max - 1,
                        file: posInfos.file
                    }) : pos
                );
            }
        }
        #if !(completion || display)
        return Context.parse('null', pos);
        #else
        var resExpr:Expr = {
            expr: EConst(CString(s, kind)),
            pos: pos
        };
        return macro cast $resExpr;
        #end

    }

}

class XMacroEscape {
	public var expr:Expr;
	public function new(expr:Expr) this.expr = expr;
}

#end
