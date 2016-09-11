/**
 * XorShift32
 * @author Sad Juno
 * @version 201605
 * @see <a href="https://blog.visvirial.com/articles/575">Google Chromeが採用した、擬似乱数生成アルゴリズム「xorshift」の数理</a>
 */
 
final class XorShift32
{
  private long value;
  private float nextNextGaussian;
  private boolean haveNextGaussian = false;
 
  XorShift32(int seed)
  {
    value = seed;
  }
  XorShift32()
  {
    this((int)random(Integer.MAX_VALUE));
  }
  long nextUnsignedInt()
  {
    long v = value;
    v = (v ^ (v << 13)) & 0xFFFFFFFFL;
    v = (v ^ (v >> 17)) & 0xFFFFFFFFL;
    v = (v ^ (v << 15)) & 0xFFFFFFFFL;
    value = v & 0xFFFFFFFFL;
    return value;
  }
  float nextFloat() {
   return nextUnsignedInt() / (float)0xFFFFFFFFL; 
  }
  float nextGaussian() {
   if (haveNextGaussian) {
     haveNextGaussian = false;
     return nextNextGaussian;
   }
   else {
     float v1 = 0;
     float v2 = 0;
     float s = 0;
     while (s == 0 || 1 <= s) {
       v1 = 2 * nextFloat() - 1;
       v2 = 2 * nextFloat() - 1;
       s = v1 * v1 + v2 * v2;
     }
     double multiplier = StrictMath.sqrt(-2 * StrictMath.log(s) / s);
     nextNextGaussian = (float)(v2 * multiplier);
     haveNextGaussian = true;
     return (float)(v1 * multiplier);
   }
  }
}