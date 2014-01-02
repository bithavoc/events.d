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
    alias void delegate(Trigger trigger, bool activated) activationDelegate;
    private:
        delegateType[] _list;
        Trigger _trigger;

        void notify(EventListOperation operation, delegateType item, size_t previousCount) {
            if(_trigger !is null) {
                if(_trigger.changed) {
                    _trigger.changed(operation, item);
                }
                auto subscriptionCount = normalizedCount;
                if(_trigger.activation !is null && ((previousCount == 0 && subscriptionCount == 1) || (previousCount == 1 && subscriptionCount == 0))) {
                    _trigger.activation(_trigger, this.active); 
                }
            }
        }
        @property size_t normalizedCount() {
            return _trigger !is null ? _trigger.count : 0;
        }
    public:

        @property bool active() {
            return normalizedCount != 0;
        }

        auto opBinary(string op)(delegateType rhs) {
            static if (op == "^") {
                this.add(rhs);
            }
            else static assert(0, "Operator "~op~" not implemented");
            return this;
        }

        void add(delegateType item) {
            auto oldCount = normalizedCount;
            _list ~= item;
            this.notify(EventListOperation.Added, item, oldCount);
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

            activationDelegate activation;

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
            return this.own(null);
        }

        auto own(activationDelegate activation) {
            if(_trigger !is null) {
                throw new Exception("Event already owned");
            }
            _trigger = new Trigger;
            _trigger.activation = activation;
            return _trigger;
        }

        void remove(delegateType item) {
            import std.algorithm : countUntil, remove;
            auto oldCount = normalizedCount;
            auto i = _list.countUntil(item);
            if(i > -1) {
                _list = _list.remove(i);
            }
            notify(EventListOperation.Removed, item, oldCount);
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
