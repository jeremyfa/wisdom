package;

import js.Browser.document;
import js.Browser.window;
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

        final wisdom = new Wisdom([ClassModule.module(), StyleModule.module(), PropsModule.module(), AttributesModule.module(), ListenersModule.module()], new HtmlBackend());

        var cities = ['Paris', 'New York', 'Madrid'];

        #if tracker

        // Example with reactivity and tracker library

        wisdom.reactive(
            document.getElementById('container'),
            () -> '<>

            <div class="align-left-$name">

                <!-- hello -->

                <p style=${{ color: "blue$city", fontWeight: 'bold' }}>All cities:</p>

                <foreach $cities ${(i:Int, city:String) -> '<>
                    <key ${city.toLowerCase().replace(' ','-')} />

                    <if ${name == 'Bob 12'}>
                        <HelloAndCount name="A1 $name in A1" />
                        <p>Another tag</p>
                    <elseif ${name == 'Bob 15'}>
                        <HelloAndCount name="B $name in B" />
                    <else>
                        <HelloAndCount name="C $name in ${city.toLowerCase()}" />
                    </if>

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
