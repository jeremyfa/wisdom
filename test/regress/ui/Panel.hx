package ui;

import wisdom.Component;

/**
 * A docking panel: its content is whatever the application puts inside, its
 * identity is `name` (not `id`, which tracker.Entity already declares). The
 * layout component finds the child to render for a host through this name.
 */
class Panel extends Component {

    public static var destroyedCount:Int = 0;

    @props public var name:String = '';

    function render() '<>
        <div class="panel" data-panel=$name>$children</div>
    ';

    override function destroy() {
        destroyedCount++;
        super.destroy();
    }

}
