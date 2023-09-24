local Str = ::std.Str, Re = ::std.Re, Debug = ::std.Debug, Util = ::std.Util, Array = ::std.Array;

function assertEq(a, b) {
    if (Util.deepEq(a, b)) return;
    throw "assertEq failed:\na = " + Debug.pp(a) + "b = " + Debug.pp(b);
}

// Taken from modding hooks
::rng_new <- function(seed = 0)
{
  if(seed == 0) seed = (Time.getRealTimeF() * 1000000000).tointeger();
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
  }
}
