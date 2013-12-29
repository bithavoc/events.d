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
import std.container;
import std.string;
import std.range;

enum EventListOperation {
    Unknown,
    Added,
    Removed
}

class EventList(TReturn, Args...) {

    alias TReturn delegate(Args) delegateType;
    private:
        delegateType[] _list;
        Trigger _trigger;

        void notify(EventListOperation operation, delegateType item) {
            if(_trigger !is null && _trigger.changed) {
                _trigger.changed(operation, item);
            }
        }
    public:

        auto opBinary(string op)(delegateType rhs) {
            static if (op == "^") {
                this.add(rhs);
            }
            else static assert(0, "Operator "~op~" not implemented");
            return this;
        }

        void add(delegateType item) {
            _list ~= item;
            this.notify(EventListOperation.Added, item);
        }

        protected TReturn onExecute(delegateType item, Args args) {
            return item(args);
        }

        final class Trigger {
            package:

            // protect constructor, use EventList.own instead
            this() {

            }

            public:

            void delegate(EventListOperation operation, delegateType item) changed;

            auto opCall(Args args) {
                return execute(args);
            }

            auto execute(Args args) {
                static if (is( TReturn == void )) {
                    // it's void returning, don't do anything
                    foreach(d;_list) {
                        return this.outer.onExecute(d, args);
                    }
                } else {
                    // execute saving the last result
                    TReturn v;
                    foreach(d;_list) {
                        v = this.outer.onExecute(d, args);
                    }
                    return v;
                }
            }

            @property size_t count() {
                return _list.length;
            }

        }

        auto own() {
            if(_trigger !is null) {
                throw new Exception("Event already owned");
            }
            return _trigger = new Trigger;
        }

        void remove(delegateType item) {
            auto r = _list.find(item).take(1);
            delegateType[] newList;
            foreach(existingItem; _list) {
                if(existingItem != item) {
                    newList ~= existingItem;
                }
            }
            _list = newList;
            notify(EventListOperation.Removed, item);
        }

}

import core.thread;

class FiberedEventList(TReturn, Args...) : EventList!(TReturn, Args) {
    protected override TReturn onExecute(TReturn delegate(Args) item, Args args) {
        static if (is( TReturn == void )) {
            // it's void returning, don't do anything
            Fiber fiber = new Fiber( {
                item(args);             
            });
            fiber.call;
        } else {
            // execute saving the last result
            TReturn v;
            Fiber fiber = new Fiber( {
                v = item(args);             
            });
            fiber.call;
            return v;
        }
    }
}
