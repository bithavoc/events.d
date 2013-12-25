import std.stdio;
import events;

void main() {
    auto event = new EventList!void;
    auto trigger = event.own;

    event ^ {
        "first subscription".writeln;
    };

    event ^ {
        "second subscription".writeln;
    };

    trigger();
}
