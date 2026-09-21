package glext;

/**
 * Payload of the bubbling events (stackCreated, itemCreated...). `origin` is
 * the emitting item, typed EventEmitter in the .d.ts, hence Dynamic + cast.
 */
extern class BubblingEvent {
    var name(default, never):String;
    var origin(default, never):Dynamic;
}
