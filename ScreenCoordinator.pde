/**
 * ScreenCoordinator
 * @author Sad Juno
 * @version 201605
 */

final class ScreenCoordinator
{
  private final float scale;
  
  ScreenCoordinator(float screenScale)
  {
    scale = screenScale;
  }
  float getScaledValue(float source)
  {
    return source * scale;
  }
  int getWidth()
  {
    return (int)(1280 * scale);  
  }
  int getHeight()
  {
    return (int)(720 * scale);  
  }
}