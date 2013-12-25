import std.stdio;
import std.string;
import events;

void main() {
    auto event = new EventList!(string, int);
    auto trigger = event.own;

    trigger.changed = (op, item) {
        "%s %s".format(op, item).writeln;
    };

    event ^ (age) {
        return "first age is %d".format(age);
    };

    event ^ (age) {
        return "second age is %d".format(age);
    };

    event.add((age) {
        return "third age is %d".format(age);
    });

    auto text = trigger(30);
    text.writeln;
}
