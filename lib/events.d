// Copyright (c) 2013 Heapsource.com and Contributors - http://www.heapsource.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

module events;

import std.stdio;
import std.algorithm;
import std.string;

/*
// event list declared with string return value, first parameter as string and second parameters as int.
static EventList!(string, string, int) formatter;

// event list declared with no parameters and returning void.
static EventList!void voidEvents;

void main() {
auto a = 2;

formatter = new EventList!(string, string, int)();

// add a delegate to the list
formatter.add((text, value){
a++;
return text.format(value);
});

// same operation but with ^ 
formatter ^ (text, value) {
return "replaced by last call";
};
auto formatterTrigger = formatter.own;

auto text = formatterTrigger("hello %d", 23);
text.writeln;

voidEvents = new EventList!void;
auto voidEventsTrigger = voidEvents.own;
voidEventsTrigger.changed = (operation, dele) {
"subscription executed".writeln;
};
voidEvents ^ {
"simple to execute".writeln;
};
voidEventsTrigger();
}
 */

enum EventListOperation {
    Unknown,
    Added,
    Removed
}

class EventList(TReturn, Args...) {

    private:
        TReturn delegate(Args)[] _list;
        Trigger _trigger;

        void notify(EventListOperation operation, TReturn delegate(Args) item) {
            if(_trigger !is null && _trigger.changed) {
                _trigger.changed(operation, item);
            }
        }
    public:

        auto opBinary(string op)(TReturn delegate(Args) rhs) {
            static if (op == "^") {
                this.add(rhs);
            }
            else static assert(0, "Operator "~op~" not implemented");
            return this;
        }

        void add(TReturn delegate(Args args) item) {
            _list ~= item;
            this.notify(EventListOperation.Added, item);
        }


        final class Trigger {
package:

            // protect constructor, use EventList.own instead
            this() {

            }

            public:

            void delegate(EventListOperation operation, TReturn delegate(Args) item) changed;

            auto opCall(Args args) {
                return execute(args);
            }
            auto execute(Args args) {
                static if (is( TReturn == void )) {
                    // it's void returning, don't do anything
                    foreach(d;_list) {
                        d(args);
                    }
                } else {
                    // execute saving the last result
                    TReturn v;
                    foreach(d;_list) {
                        v = d(args);
                    }
                    return v;
                }
            }
        }

        auto own() {
            if(_trigger !is null) {
                throw new Exception("Event already owned");
            }
            return _trigger = new Trigger;
        }
}
