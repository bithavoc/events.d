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

module events_test;
import events;
import std.stdio;

unittest {
    {
        // void event list
        int executedCount = 0;
        auto list = new EventList!void;
        list.add({
                executedCount++;
                });
        auto trigger = list.own;
        assert(trigger !is null, "trigger can not be null");
        trigger();
        assert(executedCount > 0);
    }
    {
        // trigger execute with return type event list
        auto list = new EventList!int;
        list.add({
            return 2000;
        });
        auto trigger = list.own;
        assert(trigger() == 2000, "delegate was supposed to return the value to the trigger call");
        assert(trigger.execute() == 2000, "delegate was supposed to return the value to the trigger call");
    }
    {
        // trigger execute with return type event list and syntax sugar
        auto list = new EventList!int;
        list ^ {
            return 3000;
        };
        auto trigger = list.own;
        assert(trigger() == 3000, "delegate was supposed to return the value to the trigger call");
        assert(trigger.execute() == 3000, "delegate was supposed to return the value to the trigger call");
    }
    {
        // trigger execute with return type event list and syntax sugar and multiple params
        import std.string;
        auto list = new EventList!(string, int);
        list ^ (v) {
            return format("Value is %d", v);
        };
        auto trigger = list.own;
        assert(trigger(2000) == "Value is 2000", "delegate was supposed to return the value to the trigger call");
        assert(trigger.execute(2000) == "Value is 2000", "delegate was supposed to return the value to the trigger call");
    }
    {
        // trigger changes events
        import std.string;
        auto list = new EventList!(string, int);
        auto trigger = list.own;
        string delegate(int) changedItem;
        EventListOperation itemOperation;
        trigger.changed = (op, item) {
            changedItem = item;
            itemOperation = op;
        };
        string delegate(int) originalItem = (v) {
            return format("Value is %d", v);
        };
        list ^ originalItem; // subscribe original item
        assert(trigger(10) == "Value is 10");
        assert(itemOperation is EventListOperation.Added, "op is %d".format(itemOperation));
        assert(changedItem == originalItem);
    }
    {
        // owning can't happen two times
        auto list = new EventList!void;
        list.add({
                // nop
        });
        auto trigger = list.own;
        Exception lastException;
        try {
            // this should raise and exception, the trigger is already owned.
            trigger = list.own;
        } catch (Exception ex) {
            lastException = ex;
        }
        trigger();
        assert(lastException !is null);
    }
    {
        import core.thread;
        // Void Fibered Event List
        auto list = new FiberedEventList!void;
        auto trigger = list.own;
        Fiber executedFiber = null;
        Fiber executedFiber2 = null;
        list ^ {
            executedFiber = Fiber.getThis;
        };
        list ^ {
            executedFiber2 = Fiber.getThis;
        };
        trigger();
        assert(executedFiber !is null, "the delegate must be invoked inside a fiber");
        assert(executedFiber != executedFiber2, "make sure every delegate gets it's own Fiber");
    }
    {
        import core.thread;
        // Return Fibered Event List
        auto list = new FiberedEventList!(int);
        auto trigger = list.own;
        Fiber executedFiber = null;
        Fiber executedFiber2 = null;
        list ^ {
            executedFiber = Fiber.getThis;
            return 10;
        };
        list ^ {
            executedFiber2 = Fiber.getThis;
            return 20;
        };
        int result = trigger();
        assert(result == 20);
        assert(executedFiber !is null, "the delegate must be invoked inside a fiber");
        assert(executedFiber != executedFiber2, "make sure every delegate gets it's own Fiber");
    }
    {
        // events count via trigger and remove
        auto list = new EventList!int;
        auto trigger = list.own;

        // hold delegate instance so we can remove it later on
        auto del1 = delegate int {
            return 2000;
        };
        list ^ del1;
        assert(trigger.count == 1, "the list of subscriptions must be 1");

        auto del2 = delegate int {
            return 3000;
        };
        list ^ del2;
        assert(trigger.count == 2, "the list of subscriptions must be 2 since a new delegate was subscribed");
        assert(trigger() == 3000, "the return value must be the return value of the last delegate");

        int delegate() itemRemoved;
        trigger.changed = (op, item) {
            if(op == EventListOperation.Removed) {
                itemRemoved = item;
            }
        };

        list.remove(del2);
        assert(trigger.count == 1, "the list of subscriptions must be 1 since we just removed a subscription");
        assert(trigger() == 2000, "the return value must be the return value of the remaining last delegate");
        assert(del2 == itemRemoved, "Trigger.changed event should have been called with the operation Remove and the given delegate instance being removed");
        
    }
    {
        // activation
        auto list = new EventList!void;
        bool[] activationEvents;
        auto trigger = list.own((activated) {
           activationEvents ~= activated; 
        });

        // hold delegate instance so we can remove it later on
        auto del1 = delegate void { };
        list ^ del1;

        auto del2 = delegate void { };
        list ^ del2;

        list.remove(del1);
        list.remove(del2);

        assert(activationEvents == [true, false], "there must be one 1 activation event and 1 deactivation");
        
    }
    writeln("tests just ran");
} // test
