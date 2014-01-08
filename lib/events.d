// Copyright (c) 2013, 2014 Heapsource.com and Contributors - http://www.heapsource.com
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
import core.thread : Fiber;

enum EventOperation {
    Unknown,
    Added,
    Removed
}

abstract class Event(TReturn, Args...) {
    alias TReturn delegate(Args) delegateType;
  
    public: 
        @property abstract bool active();

        auto opBinary(string op)(delegateType rhs) {
            static if (op == "^") {
                this.add(rhs);
            }
            else static if (op == "^^") {
                this.addAsync(rhs);
            }
            else static assert(0, "Operator "~op~" not implemented");
            return this;
        }

        final void add(delegateType item) {
            auto oldCount = normalizedCount;
            onAdd(item, oldCount);
        }

        final void addAsync(delegateType item) {
            auto fibered = delegate TReturn(Args args) {
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
            };
            this.add(fibered);
        }

        final void remove(delegateType item) {
            auto oldCount = normalizedCount;
            onRemove(item, oldCount);
        }
    protected:

        void onAdd(delegateType item, size_t oldCount) {
            this.onChanged(EventOperation.Added, item, oldCount);
        }

        void onRemove(delegateType item, size_t oldCount) {
            this.onChanged(EventOperation.Removed, item, oldCount);
        }

        TReturn onExecute(delegateType item, Args args) {
            return item(args);
        }
        
        @property size_t normalizedCount();
        
        void onChanged(EventOperation operation, delegateType item, size_t oldCount);
}

class EventList(TReturn, Args...) : Event!(TReturn, Args) {
        alias void delegate(Trigger trigger, bool activated) activationDelegate;
    private:
        delegateType[] _list;
        Trigger _trigger;
    public:
        @property override bool active() {
            return normalizedCount != 0;
        }

        final class Trigger {
            package:

            // protect constructor, use EventList.own instead
            this() {

            }

            public:

            void delegate(EventOperation operation, delegateType item) changed;

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

            void reset() {
                foreach(d;_list) {
                    remove(d);
                }
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

    protected:

        override void onAdd(delegateType item, size_t oldCount) {
            _list ~= item;
            super.onAdd(item, oldCount);
        }

        override void onRemove(delegateType item, size_t oldCount) {
            import std.algorithm : countUntil, remove;
            auto i = _list.countUntil(item);
            if(i > -1) {
                _list = _list.remove(i);
            }
            super.onRemove(item, oldCount);
        }
        
        override @property size_t normalizedCount() {
            return _trigger !is null ? _trigger.count : 0;
        }
        
        override void onChanged(EventOperation operation, delegateType item, size_t oldCount) {
            if(_trigger !is null) {
                if(_trigger.changed) {
                    _trigger.changed(operation, item);
                }
                auto subscriptionCount = normalizedCount;
                if(_trigger.activation !is null && ((oldCount == 0 && subscriptionCount == 1) || (oldCount == 1 && subscriptionCount == 0))) {
                    _trigger.activation(_trigger, this.active); 
                }
            }
        }

}
