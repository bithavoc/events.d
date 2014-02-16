events.d
===

events.d is an Event Object Model for the D programming language, with elegant design and beautiful syntax sugar.

## How it works

events.d main goal is to allow subscription of multiple delegates with the same signature to a List.
A trigger is then used to call the list of subscribed delegates.

### Triggers

Every event list must be owned by a caller using the method `EventsList.own`, the call will only work the first time so the best practice is to own the 
event list right after instantiation.


```D
    auto event = new EventList!void;
    auto trigger = event.own;
```

The trigger objects works like a function to call all the subscribed delegates.


```D
    trigger();
```

### Subscription

Subscription is performed by the `addSync` method:


```D
    event.addSync({
        "first subscription".writeln;
    });
```

The same operation can be performed with syntax sugar:


```D
    event ^ {
        "first subscription".writeln;
    };
```

### Unsubscription

Unsubscription or removal of delegates from the event list can be achieved with the method `remove`. The same instance of the delegate subscribed must be provided in order to properly perform the removal.

```D
        auto myDelegate = delegate int {
            return 3000;
        };
        list ^ myDelegate;
        list.remove(myDelegate) // trigger.count will now reporting one less subscription
```

Owners can use the method `Trigger.reset` to unsubscribe all the delegates from the event.

### Return Value

The first type of the EventList template is the return type, it's required even if the type is `void`:

```D
    auto event = new EventList!void;
```

The return type is reflected in the signature of the call and the delegates:


```D
    auto event = new EventList!int;
    auto trigger = event.own;
    event ^  {
        return 20;
    };
    int value  = trigger(); // value = 20
```


### Parameters

The types next to the return type belong to the parameters of the delegate:

```D
    auto mult = new EventList!(int, float);
    auto trigger = mult.own;
    mult ^  (base) {
        return base * 3;
    };
    int value  = trigger(20.0); // value = 60
```

### Advanced: Fibers

Subscribers can use the method `addAsync` or the operator `^^` to subscribe a delegate which executes in it's own fiber [Fiber](http://dlang.org/phobos/core_thread.html#.Fiber). Inside the delegate, you can capture the current Fiber using [Fiber.getThis](http://dlang.org/phobos/core_thread.html#.Fiber.getThis) part of the standard module [core.thread](http://dlang.org/phobos/core_thread.html).

```D
    import core.thread;
    ...
    auto event = new EventList!(string, int);
    auto trigger = event.own;

    event ^^ (age) {
        return "third age is %d in Fiber %s".format(age, Fiber.getThis);
    };

    auto text = trigger(30);
    text.writeln;
```

### Advanced: Watching Changes

The trigger can provide notifications to the owner about the operation beign performed in the event list:


```D
    trigger.changed = (EventOperation op, item) {
        if(op == EventOperation.Added) {
            "new delegate subscribed".writeln;
        } else if(op == EventOperation.Removed) {
            "new delegate unsubscribed".writeln;
        }
        "%s %s".format(op, item).writeln;
    };
```

### Advanced: Activation

All events are considered active once the first delegate is subscribed to the event. 
Events owners can provide a delegate to the method `own` to perform actions when the event changes it's activation state.

The main difference between the activation delegate (also setteable via `Trigger.activation`) and the changes delegate (`Trigger.changed`)
is that the changes delegates is executed unconditionally when a delegate is subscribed or unsubscribed to the event, unlike `Trigger.activation` which is only triggered under the following scenarios:

 __Active__ : The event just went from 0 subscribers to 1 subscriber.

 __Inactive__: The event just went from 1 subscriber to 0 subscribers.

Example:

```D
        auto trigger = list.own((trigger, activated) {
            if(activated) {
                "first delegate subscribed".writeln;
            } else {
                "no more delegates subscribed".writeln;
            }
        });
```

### Advanced: Actions

An action is an event that get's activated everytime a new delegate is subscribed to the action. Since actions are mostly intended to be returned by functions using closures, the subscription usually happens only one time in the lifetime of the action. A user-defined handler must be given to the action to receive the instance of the delegate that activated the action which can be fired multiple times as needed.

Example:
```D
        auto foo = function Action!(void, int)(int max) {
            auto action = new Action!(void, int)((trigger) {
                    for(int i = 0; i < max; i++) {
                        trigger(i);
                    }
            });
            return action;
        };
        int values;
        foo(5) ^= (i) {
            values+=i;
        };
        assert(values == 10);
```

The sintax sugar to subscribe in the same fiber is `^=` and `^^=` for fibered subscriptions.

### Advanced: Execution Strictness

Both classes `EventList` and `Action` allow users to use `addSync` or `addAsync` at will, however, there are scenarios where the author of the event/actions wants to enforce certain execution mode for subscriptions.

The classes `StrictEventList` and `StrictAction` allow authors enforce the execution type for the subscribers.

Example of strictly Asynchronous Action:

```D
        StrictAction!(StrictTrigger.Async, void) asyncAction;
        ...
        asyncAction.addAsync({}); // OK
        asyncAction ^^= {}; // OK
        asyncAction.addSync({}); // ERROR: fails to compile
        asyncAction ^= {}; // ERROR: fails to compile
```

Example of strictly Synchronous Action:

```D
        StrictAction!(StrictTrigger.Sync, void) syncAction;
        ...
        syncAction.addAsync({}); // ERROR: fails to compile
        syncAction ^^= {}; // ERROR: fails to compile
        syncAction.addSync({}); // OK
        syncAction ^= {}; // OK
```

Example of strictly Asynchronous Event:

```D
        StrictEventList!(StrictTrigger.Async, void) asyncEvent;
        ...
        asyncEvent.addAsync({}); // OK
        asyncEvent ^^ {}; // OK
        asyncEvent.addSync({}); // ERROR: fails to compile
        asyncEvent ^ {}; // ERROR: fails to compile
```

Example of strictly Asynchronous Event:

```D
        StrictEventList!(StrictTrigger.Sync, void) syncEvent;
        ...
        syncEvent.addAsync({}); // ERROR: fails to compile
        syncEvent ^^ {}; // ERROR: fails to compile
        syncEvent.addSync({}); // OK
        syncEvent ^ {}; // OK
```


## Building

    git clone https://github.com/heapsource/events.d.git
    make

You can set the env variable DEBUG=1 to enable compilation with debugging capabilities.

    DEBUG=1 make

## Examples

Use `make examples` to compile all the examples. Executables will be generated in the directory `out/`.


## Test


    make tests


## License (MIT)

Copyright (c) 2013, 2014 Heapsource.com - http://www.heapsource.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
