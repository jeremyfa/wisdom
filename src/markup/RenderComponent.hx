package markup;

import markup.ReactiveContext;

typedef RenderComponent = (comp:(xid:Xid, ctx:ReactiveContext, data:VNodeData, children:Array<VNode>)->Any, xid:Xid, data:VNodeData, children:Array<VNode>)->Any;
