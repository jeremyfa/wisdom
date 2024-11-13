package testcomp;

import wisdom.X;

class TestComp implements X {

    @x public static function HelloAndCount2(
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

}
