package;

import testcomp.HelloAndCount3;
import wisdom.Component;
import wisdom.HtmlBackend;
import wisdom.VNode;
import wisdom.Wisdom;
import wisdom.X;
import wisdom.modules.AttributesModule;
import wisdom.modules.ClassModule;
import wisdom.modules.ListenersModule;
import wisdom.modules.PropsModule;
import wisdom.modules.StyleModule;

using StringTools;
#if wisdom_html
import js.Browser.document;
import js.Browser.window;
#end


#if tracker
import tracker.Observable;
#end

class TestComp2 extends Component
{
    @props var name:String;

    @observe var count:Int = 0;

    function increment()
    {
        count++;
    }

    function render() '<>
        <div onclick=$increment>
            Count: $count
        </div>
    ';
}

class Main implements X #if tracker implements Observable #end {

    #if tracker

    // Component with state, only supported with tracker and reactivity

    @x function HelloAndCount(
        @state count:Int = 0,
        name:String
    ) {

        function increment() {
            count++;
        }

        return '<>
            <div onclick=$increment>
                Hello $name<br />
                Count: ${count}
            </div>
        ';

    }

    @x function HelloCount(
        name:String,
        @state count:Int = 0,
        children:Array<VNode>
    ) {
        function increment()
        {
            count++;
        }

        return '<>
            <div>
                <h1>Hello $name</h1> <br/>
                <div onclick=$increment>
                    Count $count
                </div>
                $children
            </div>
        ';
    }

    #end

    public static function main() {

        static final _main = new Main();

    }

    /**
     * Observable variable. Changing it will trigger
     * reactive vdom update on those that depend in the variable.
     */
    @observe var name:String = 'John';

    function new() {

        final wisdom = new Wisdom([
            ClassModule.module(), StyleModule.module(), PropsModule.module(), AttributesModule.module(), ListenersModule.module()],
            #if wisdom_html
            new HtmlBackend()
            #else
            null // TODO
            #end
        );

        var cities = ['Paris', 'New York', 'Madrid'];
        var names = ['John', 'Jane', 'Alan', 'Ellen', 'Jeremy', 'Joanna', 'Bob', 'Lucy'];

        #if tracker

        // Example with reactivity and tracker library

        wisdom.reactive(
            #if wisdom_html
            document.getElementById('container')
            #else
            null // TODO
            #end,
            () -> '<>

            <div class="cities-list">

                <p style=${{ color: "blue", fontWeight: 'bold' }}>All cities:</p>

                // Looping through each city
                <foreach $cities ${(i:Int, city:String) -> '<>

                    // Allows to reorder cities without loosing each
                    // iteration component state (HelloAndCount)
                    <key ${city.toLowerCase().replace(' ','-')} />

                    // Invoke a custom component
                    <HelloAndCount3 name=$name />
                    // <testcomp.TestComp.HelloAndCount2 name=$name />

                    <p
                    style=${{ color: "green" }}
                    class="city-info">
                        Hello $name,<br />from $city!

                        // Tag guarded with a condition
                        <p style=${{ fontWeight: 'bold' }} if=${city == "Paris"}>Bonjour !</p>
                    </p>

                '} />

            </div>

        ');

        // Change name over time
        var ticks = 1;
        #if wisdom_html
        window.setInterval(() -> {
            name = names[ticks % names.length];
            ticks++;
        }, 1000);
        #end

        #else

        // Example without reactivity and tracker library

        wisdom.patch(
            #if wisdom_html
            document.getElementById('container')
            #else
            null // TODO
            #end,
            '<>
                <div class="align-left">

                    <!-- hello -->

                    <p style=${{ color: 'blue', fontWeight: 'bold' }}>All cities:</p>

                    <foreach $cities ${(i:Int, city:String) -> '<>
                        <key ${city.toLowerCase().replace(' ','-')} />

                        <p key=${name+'-'+city} class="city-info">
                            Hello $name, from $city!

                            <p style=${{ fontWeight: 'bold', color: 'purple' }} if=${city == "Paris"}>Bonjour !</p>
                            <p style=${{ fontWeight: 'bold', color: 'purple' }} if=${city == "New York"}>Hi!</p>
                        </p>

                    '} />

                </div>
        ');

        #end

    }

}
