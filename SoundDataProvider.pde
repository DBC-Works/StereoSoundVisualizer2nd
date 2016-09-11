/**
 * ScreenCoordinator
 * @author Sad Juno
 * @version 201605
 * @see <a href="http://code.compartmental.net/minim/javadoc/">Minim Javadoc</a>
 */

import ddf.minim.AudioPlayer;
import ddf.minim.Minim;
import ddf.minim.analysis.FFT;

class SoundDataProvider
{
  final AudioPlayer player;
  final FFT rightFft;
  final FFT leftFft;

  private final Minim minim;

  SoundDataProvider(PApplet applet, String filePath)
  {
    minim = new Minim(applet);
    player = minim.loadFile(filePath, 1024);
    rightFft = new FFT(player.bufferSize(), player.sampleRate());
    leftFft = new FFT(player.bufferSize(), player.sampleRate());
    rightFft.window(FFT.HAMMING);
    leftFft.window(FFT.HAMMING);
  }
  boolean paused()
  {
    return player != null && player.position() < player.length();
  }
  SoundDataProvider play()
  {
    if (player != null) {
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