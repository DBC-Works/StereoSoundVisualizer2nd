/**
 * SoundDataProvider
 * @author Sad Juno
 * @version 201712
 * @see <a href="http://code.compartmental.net/minim/javadoc/">Minim Javadoc</a>
 */

import java.util.AbstractMap.SimpleEntry;
import ddf.minim.AudioPlayer;
import ddf.minim.Minim;
import ddf.minim.analysis.BeatDetect;
import ddf.minim.analysis.FFT;

class SoundDataProvider
{
  final AudioPlayer player;
  final FFT rightFft;
  final FFT leftFft;
  final float initialFrameRate;

  private final Minim minim;
  protected long startTimeMs = -1;

  SoundDataProvider(PApplet applet, String filePath, float fr)
  {
    minim = new Minim(applet);
    player = minim.loadFile(filePath, 1024);
    rightFft = new FFT(player.bufferSize(), player.sampleRate());
    leftFft = new FFT(player.bufferSize(), player.sampleRate());
    rightFft.window(FFT.HAMMING);
    leftFft.window(FFT.HAMMING);
    initialFrameRate = fr;
  }
  boolean paused()
  {
    return player != null && player.position() < player.length();
  }
  SoundDataProvider play()
  {
    if (player != null) {
      if (startTimeMs < 0) {
        startTimeMs = System.currentTimeMillis();
      }
      player.play();
    }
    return this;
  }
  SoundDataProvider pause()
  {
    if (player != null) {
      player.pause();
    }
    return this;
  }
  SoundDataProvider stop()
  {
    if (player != null) {
      player.close();
    }
    if (minim != null) {
      minim.stop();
    }
    return this;
  }
  SoundDataProvider update()
  {
    rightFft.forward(player.right);
    leftFft.forward(player.left);
    doUpdate();
    return this;
  }
  protected void doUpdate()
  {
  }
}

final class MusicDataProvider extends SoundDataProvider
{
  private float beatPerMinute;
  private final BeatDetect beatDetector;
  
  MusicDataProvider(PApplet applet, String filePath, float fr, float bpm)
  {
    super(applet, filePath, fr);
    
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
  float getCrotchetQuantityFrame()
  {
    return getCrotchetQuantitySecond() * initialFrameRate;
  }
  float getMeasureLengthSecond(int beatCount)
  {
    return getCrotchetQuantitySecond() * beatCount;
  }
  float getElapsedTimeMs()
  {
    return 0 < startTimeMs ? System.currentTimeMillis() - startTimeMs : 0;
  }
  float getElapsedTimeAsQuantitySecond()
  {
    return (getElapsedTimeMs() / 1000) / getCrotchetQuantitySecond();
  }
  SimpleEntry< List< List< Float > >, List< List< Float > > > getOctavedLevels()
  {
    List< List< Float > > rightLevels = new ArrayList< List< Float > >();
    List< List< Float > > leftLevels = new ArrayList< List< Float > >();
    
    float maxFreq = rightFft.indexToFreq(rightFft.specSize() - 1);
    float beginFreq = 0;
    float endFreq = 27.5;
    while (endFreq < maxFreq) {
      rightLevels.add(getLevelsInRange(beginFreq, endFreq, rightFft));
      leftLevels.add(getLevelsInRange(beginFreq, endFreq, leftFft));
      
      beginFreq = endFreq;
      endFreq = endFreq * 2;
    }
    return new SimpleEntry< List< List< Float > >, List< List< Float > > >(rightLevels, leftLevels);
  }
  private List<Float> getLevelsInRange(float beginFreq, float endFreq, FFT fft)
  {
      List<Float> levels = new ArrayList<Float>();
      for (int index = fft.freqToIndex(beginFreq); index < fft.freqToIndex(endFreq); ++index) {
        levels.add(fft.getBand(index));
      }
      return levels;
  }

  protected void doUpdate()
  {
    beatDetector.detect(player.mix);
  }
}