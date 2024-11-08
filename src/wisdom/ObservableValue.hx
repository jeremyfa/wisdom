package wisdom;

#if tracker

import tracker.Observable;

class ObservableValue implements Observable {

    @observe public var value:Any = null;

    public function new(value:Any) {
        this.value = value;
    }

}

#end
