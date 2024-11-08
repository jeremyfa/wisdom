package;

import js.Browser.document;
import js.Browser.window;
import markup.HtmlBackend;
import markup.Markup;
import markup.X;
import markup.modules.AttributesModule;
import markup.modules.ClassModule;
import markup.modules.ListenersModule;
import markup.modules.PropsModule;
import markup.modules.StyleModule;

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
                Hello $name
                Count: ${count}
            </div>
        ';

    }

    #end

    public static function main() {

        static final _main = new Main();

    }

    @observe var name:String = 'John';

    function new() {

        final markup = new Markup([ClassModule.module(), StyleModule.module(), PropsModule.module(), AttributesModule.module(), ListenersModule.module()], new HtmlBackend());

        var cities = ['Paris', 'New York', 'Madrid'];

        #if tracker

        // Example with reactivity and tracker library

        markup.reactiveVDom(
            document.getElementById('container'),
            () -> '<>

            <div class="align-left">

                <!-- hello -->

                <p style=${{ color: 'blue', fontWeight: 'bold' }}>All cities:</p>

                <foreach $cities ${(i:Int, city:String) -> '<>
                    <key ${city.toLowerCase().replace(' ','-')} />

                    <HelloAndCount name="$name in ${city.toLowerCase()}" />

                    <p key=${name+'-'+city}
                    style=${{ color: "green" }} class="city-info">
                        Hello $name, from $city!

                        <p style=${{ fontWeight: 'bold' }} if=${city == "Paris"}>Bonjour !</p>
                        <p style=${{ fontWeight: 'bold' }} if=${city == "New York"}>Hi!</p>
                    </p>

                '} />

            </div>

        ');

        var ticks = 1;
        window.setInterval(() -> {
            name = 'Bob $ticks';
            ticks++;
        }, 1000);

        #else

        // Example without reactivity and tracker library

        markup.patch(
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
