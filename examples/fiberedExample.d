import std.stdio;
import std.string;
import events;
import core.thread;

void main() {
    auto event = new EventList!(string, int);
    auto trigger = event.own;

    event ^^ (age) {
        return "third age is %d in Fiber %s".format(age, Fiber.getThis);
    };

    auto text = trigger(30);
    text.writeln;
}
