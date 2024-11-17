package testcomp;

class HelloAndCount3 extends wisdom.Component {

    @props var name:String;

    @observe var count:Int = 0;

    function increment() {

        count++;

    }

    function render() '<>

        <div onclick=$increment>
            Hello3 $name<br />
            Count: ${count}
        </div>

    ';

}
