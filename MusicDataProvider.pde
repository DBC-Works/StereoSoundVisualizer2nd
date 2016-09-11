/**
 * MusicDaraProvider
 * @author Sad Juno
 * @version 201605
 */
 
import ddf.minim.analysis.BeatDetect;

final class MusicDataProvider extends SoundDataProvider
{
  private float beatPerMinute;
  private final BeatDetect beatDetector;
  
  MusicDataProvider(PApplet applet, String filePath, float bpm)
  {
    super(applet, filePath);
    
    beatPerMinute = bpm;
    beatDetector = new BeatDetect();
    beatDetector.detectMode(BeatDetect.FREQ_ENERGY);
  }

  float getBeatPerMinute()
  {
    return beatPerMinute;
  }
  MusicDataProvider setBeatPerMinute(float bpm)
  {
    beatPerMinute = bpm;
    return this;
  }
  float getCrotchetQuantitySecond()
  {
    return (float)(60.0 / beatPerMinute);
  }
  float getMeasureLengthSecond(int beatCount)
  {
    return getCrotchetQuantitySecond() * beatCount;
  }

  protected void doUpdate()
  {
    beatDetector.detect(player.mix);
  }
}