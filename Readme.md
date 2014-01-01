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

Subscription is performed by the `add` method:


```D
    event.add({
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

A derived class of `EventList` called `FiberedEventList` executes every subscribed delegate of the event list in a different [Fiber](http://dlang.org/phobos/core_thread.html#.Fiber). Inside the delegate, you can capture the current Fiber using [Fiber.getThis](http://dlang.org/phobos/core_thread.html#.Fiber.getThis) part of the standard module [core.thread](http://dlang.org/phobos/core_thread.html).

```D
    import core.thread;
    ...
    auto event = new FiberedEventList!(string, int);
    auto trigger = event.own;

    event ^ (age) {
        return "third age is %d in Fiber %s".format(age, Fiber.getThis);
    };

    auto text = trigger(30);
    text.writeln;
```

### Advanced: Watching Changes

The trigger can provide notifications to the owner about the operation beign performed in the event list:


```D
    trigger.changed = (EventListOperation op, item) {
        if(op == EventListOperation.Added) {
            "new delegate subscribed".writeln;
        } else if(op == EventListOperation.Removed) {
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

## Building

    git clone https://github.com/heapsource/events.d.git
    make


## Examples

Use `make examples` to compile all the examples. Executables will be generated in the directory `out/`.


## Test


    make tests


## License (MIT)

Copyright (c) 2013 Heapsource.com - http://www.heapsource.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
