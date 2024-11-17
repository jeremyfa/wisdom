package;

import js.Browser.document;
import js.Browser.window;
import testcomp.HelloAndCount3;
import wisdom.HtmlBackend;
import wisdom.Wisdom;
import wisdom.X;
import wisdom.modules.AttributesModule;
import wisdom.modules.ClassModule;
import wisdom.modules.ListenersModule;
import wisdom.modules.PropsModule;
import wisdom.modules.StyleModule;

using StringTools;

#if tracker
import tracker.Observable;
#end

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

        final wisdom = new Wisdom([ClassModule.module(), StyleModule.module(), PropsModule.module(), AttributesModule.module(), ListenersModule.module()], new HtmlBackend());

        var cities = ['Paris', 'New York', 'Madrid'];
        var names = ['John', 'Jane', 'Alan', 'Ellen', 'Jeremy', 'Joanna', 'Bob', 'Lucy'];

        #if tracker

        // Example with reactivity and tracker library

        wisdom.reactive(
            document.getElementById('container'),
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
        window.setInterval(() -> {
            name = names[ticks % names.length];
            ticks++;
        }, 1000);

        #else

        // Example without reactivity and tracker library

        wisdom.patch(
            document.getElementById('container'),
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
