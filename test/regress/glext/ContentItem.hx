package glext;

/** Base of ComponentItem, Stack and RowOrColumn; only what the integration reads. */
extern class ContentItem {
    var isComponent(default, never):Bool;
    var isStack(default, never):Bool;
    var contentItems(default, never):Array<ContentItem>;
    var element(default, never):js.html.Element;
    function close():Void;
}
