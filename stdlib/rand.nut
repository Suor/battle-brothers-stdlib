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

if ("rng_new" in getroottable()) {
    ::std.rng_new <- ::rng_new
} else {
    // Taken from modding hooks
    ::std.rng_new <- function(seed = 0)
    {
      if(seed == 0)
        // add time() here to work outside of BB
        seed = ("Time" in getroottable()) ? (Time.getRealTimeF() * 1000000000).tointeger() : time();
      return {
        x = seed, y = 234567891, z = 345678912, w = 456789123, c = 0,
        nextInt = function()
        {
          x += 1411392427;

          y = y ^ (y<<5);
          y = y ^ (y>>>7);
          y = y ^ (y<<22);

          local t = z + w + c;
          z  = w;
          c  = t >>> 31; // c = (signed)t < 0 ? 1 : 0
          w  = t & 0x7FFFFFFF;

          return (x + y + w) & 0x7FFFFFFF;
        },
        nextFloat = function()
        {
          return nextInt() / 2147483648.0;
        },
        next = function(a, b = null)
        {
          if(b == null)
          {
            if(a <= 0) throw "a must be > 0";
            return nextInt() % a + 1;
          }
          else
          {
            if(a > b) throw "a must be <= than b";
            return nextInt() % (b-a+1) + a;
          }
        }
        // Added this mostly for testing purposes
        reset = function (seed) {
            x = seed, y = 234567891, z = 345678912, w = 456789123, c = 0;
            local n = next(128);
            for (local i = 0; i < n; i++) nextInt();
        }
      }
    }
}


::std.rng <- ("rng" in getroottable()) ? ::rng : ::std.rng_new();

::std.Rand <- {
    function int(a, b) {
        return ::Math.rand(a, b);
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
        // NOTE: do not use Util.merge() here to make Rand.using() available early, i.e. for Player
        local new = clone this;
        new.int = function (a, b) {
            return gen.next(a.tointeger(), b.tointeger())
        }
        return new;
    }
}
