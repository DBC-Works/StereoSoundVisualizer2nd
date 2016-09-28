/**
 * EllipseRotationVisualizer
 * @author Sad Juno
 * @version 201609
 */

final class EllipseRotationVisualizer extends Visualizer
{
  private final color fgColor;
  private final float fgHue;
  private final float fgBrightness;
  private final float fgSaturation;
  private final color bgColor;
  
  float rotationInc;
  float rotation = -1;
  float rightIntensity;
  float leftIntensity;
  float mixIntensity;
  
  EllipseRotationVisualizer(SceneInfo scene)
  {
    super(scene);
    fgColor = scene.fgColor != null ? color(Integer.decode(scene.fgColor)) : 0;
    bgColor = scene.bgColor != null ? color(Integer.decode(scene.bgColor)) : #ffffff;

    fgHue = hue(fgColor);
    fgSaturation = saturation(fgColor);
    fgBrightness = brightness(fgColor);
  }
  boolean isDrawable()
  {
    return true;
  }
  protected void doPrepare(MusicDataProvider provider, boolean isPrimary)
  {
    if (isPrimary) {
      if (rotation < 0) {
        rotationInc = 4.0 * provider.getCrotchetQuantitySecond() / fps;
        rotation = 0;
      }
      background(bgColor);
      rightIntensity = calcNewIntensity(rightIntensity, provider.player.right.level() * 4);
      leftIntensity = calcNewIntensity(leftIntensity, provider.player.left.level() * 4);
      mixIntensity = calcNewIntensity(mixIntensity, provider.player.mix.level() * 4);
    }
  }
  
  protected void doVisualize()
  {
    colorMode(HSB, 360, 100, 100, 100);
    blendMode(targetScene.blendMode);
    
    noFill();
    ellipseMode(CENTER);

    translate(width / 2, height / 2);
    rotateZ(rotation);
    rotateY(PI / 4.0 - rotation);

    int step = 60;
    float h = fgHue + step;
    if (360 <= h) {
      h -= 360;
    }
    drawEllipse(new PVector(width / 4, 0), PI - rotation, rightIntensity, h);
    h = fgHue - step;
    if (h < 0) {
      h += 360;
    }
    drawEllipse(new PVector(-width / 4, 0), TWO_PI - rotation, leftIntensity, h);
    drawEllipse(new PVector(0, 0), rotation, mixIntensity, fgHue);

    rotation += rotationInc;
    if (TWO_PI < rotation) {
      rotation = 0;
    }
  }
  private float calcNewIntensity(float oldIntensity, float newIntensity)
  {
    float value = newIntensity;
    if (oldIntensity < newIntensity) {
      if (oldIntensity < 0.1) {
        value = newIntensity;
      }
      else {
        value = oldIntensity * 1.1;
      }
    }
    else {
      value *= 0.95;
    }
    return value;
  }
  private void drawEllipse(PVector center, float rotation, float intensity, float colorHue)
  {
    strokeWeight(screenCoordinator.getScaledValue(2));
    pushMatrix();
    translate(center.x, center.y);
    
    float ratio = 0;
    float rotationX = rotation;
    boolean direction = true;
    for (int dist = 4; dist < width / 3; dist += screenCoordinator.getScaledValue(16)) {
      ratio += width / 3.0;
      rotationX += ratio * 0.00004 * (direction ? 1 : -1);
      if (TWO_PI < rotationX) {
        direction = false;
      }
      else if (rotationX < 0) {
        direction = true;
      }
      
      stroke(colorHue, fgSaturation * (1.0 - dist / (width / 2.5)), fgBrightness, intensity * 99);
      pushMatrix();
      rotateX(rotationX);
      rotateY(rotation);
      ellipse(0, 0, dist * intensity * 1.5, dist * intensity * 1.5);
      popMatrix();
    }
    popMatrix();
  }
}