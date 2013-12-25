import std.stdio;
import std.string;
import events;

void main() {
    auto event = new EventList!(void, int);
    auto trigger = event.own;

    event ^ (age) {
        "first age is %d".format(age).writeln;
    };

    event ^ (age) {
        "second age is %d".format(age).writeln;
    };
    trigger(30);
}
