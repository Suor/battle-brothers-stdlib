local Util = ::std.Util;
local Iter = ::std.Iter <- {
    function chain(...) {
        foreach (it in vargv)
            foreach (item in it) yield it;
    }
    function take(num, it) {
        local result = [];
        for (local done = 0; done < num; done++) {
            local item = resume it;
            if (item == null && it.getstatus() == "dead") break;
            result.push(item);
        }
        return result;
    }
}

::std.Rand <- {
    function int(a, b) {
        return ::Math.rand(a ,b);
    }
    function float(a = null, b = null) {
        local r = this.int(0, 2147483647) / 2147483648.0;
        if (a == null && b == null) return r;
        return a + r * (b - a);
    }
    function range(from, to) {return this.float(from, to)} // Backwards compatibility

    function chance(prob) {
        return this.float() < prob;
    }

    function index(n, weights = null, _total = null) {
        if (weights == null) return this.int(0, n - 1);
        if (n > weights.len()) throw "Not enough weights passed";

        local total = _total != null ? _total : Util.sum(weights);
        local roll = this.float() * total;
        for (local i = 0; i < n; i++) {
            roll -= weights[i];
            if (roll <= 0) return i;
        }
        return n - 1; // To be safe
    }

    function choice(options, weights = null, _total = null) {
        return options[this.index(options.len(), weights, _total)];
    }
    function choices(num, options, weights = null) {
        local res = [];
        local total = weights != null ? Util.sum(weights) : null;
        for (local i = 0; i < num; i++) res.push(this.choice(options, weights, total));
        return res;
    }
    function take(num, options, weights = null) {
        return Iter.take(num, this.itake(options, weights));
    }
    function itake(_options, _weights = null) { // generator
        local options = _options, weights = _weights;
        local total = weights ? Util.sum(_weights) : null;
        local n = options.len();
        while (n > 0) {
            local i = weights ? this.index(n, weights, total) : this.int(0, n - 1);
            yield options[i];
            // The element i should be excluded from available choices, so we move the last element
            // in its place and decrement the artificial end of both arrays.
            n--;
            if (options == _options) { // Only do clone if we need a second item
                options = clone _options;
                if (weights) weights = clone _weights;
            }
            options[i] = options[n];
            if (weights) {
                total -= weights[i];
                weights[i] = weights[n];
            }
        }
    }

    function weighted(weights, options) { // Deprecated, note the reverse param order
        return this.choice(options, weights);
    }

    function insert(arr, item, num = 1) {
        for (local i = 0; i < num; i++) {
            local index = this.int(0, arr.len());
            arr.insert(index, item);
        }
    }

    function poly(tries, prob) {
        if (prob <= 0 || tries < 1) return 0;

        local num = 0;
        for (local i = 0; i < tries; i++)
            if (this.chance(prob)) num++;
        return num;
    }

    // Create a new Rand with a replaced backend:
    //     local Rand = ::std.Rand.using(::rng);
    //     local Rand = ::std.Rand.using(::rng_new(seed));
    //     ... use it as usual ...
    function using(gen) {
        return Util.merge(this, {
            function int(a, b) {
                return a >= 0 ? gen.next(a, b) : a + gen.next(0, b - a)
            }
        })
    }
}
