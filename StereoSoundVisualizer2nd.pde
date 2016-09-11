/**
 * StereoSoundVisualizer2nd
 * for Processing 3.x
 * licensed under <a href="http://opensource.org/licenses/MIT">MIT License</a>
 * @author Sad Juno
 * @version 201609
 * @see <a href="https://github.com/DBC-Works">GitHub</a>
 */

//
// Imports
//

import java.util.Arrays;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
//import com.hamoid.*;

//
// Settings
//

// screenScale: 1.0 - HD(1280x720) / 1.5 - Full HD(1920x1080)
final float screenScale = 4 / 4.0;

// fps: Frame per second
final int fps = 15;

// recordFrame: Record frame(experimental)
final boolean recordFrame = false;

// recordSceneLastFrame: Record last frame of scene
final boolean recordSceneLastFrame = false;

// standby: Start when space key is pressed
boolean standby = false;

//
// Classes
//

interface Recorder
{
  abstract void recordFrame();
  abstract void finish();
}

final class FrameRecorder implements Recorder
{
  FrameRecorder()
  {
  }

  public void recordFrame()
  {
    saveFrame("########.tga");
  }
  
  public void finish()
  {
  }
}

/*
final class AsyncFrameRecorder implements Recorder
{
  private final LinkedBlockingQueue<int[]> queue;
  private final ExecutorService executor = Executors.newCachedThreadPool();
  private Future future;
  private volatile long frameCount;
  
  AsyncFrameRecorder()
  {
    queue = new LinkedBlockingQueue<int[]>();
  }

  void recordFrame()
  {
    loadPixels();

    try {
      queue.put(Arrays.copyOf(pixels, pixels.length));
    }
    catch (InterruptedException e) {
      println("(lost frame...)");
    }
    
    if (future == null || future.isDone()) {
      Runnable saveTask = new Runnable() {
        public void run() {
          final PImage frameImage = createImage(width, height, HSB);
          while (0 < queue.size()) {
            final String fileName = String.format("%08d.png", ++frameCount);
            try {
              frameImage.pixels = queue.take();
              frameImage.save(fileName);
            }
            catch (InterruptedException e) {
              // Do nothing
              println("(lost frame when save...)");
            }
          }
        }
      };
      future = executor.submit(saveTask);
    }
  }
  
  void finish()
  {
    if (future != null && future.isDone() == false && future.isCancelled() == false) {
      future.cancel(false);
    }
    if (executor.isShutdown() == false) {
      executor.shutdown();
    }
  }
}

final class VideoExportRecorder implements Recorder
{
  private final VideoExport videoExport;
  
  VideoExportRecorder(PApplet applet)
  {
    videoExport = new VideoExport(applet, "movie.mp4");
  }

  public void recordFrame()
  {
    videoExport.saveFrame();
  }
  
  public void finish()
  {
  }
}
 */

//
// Fields
//

ScreenCoordinator screenCoordinator = new ScreenCoordinator(screenScale);
int currentSceneIndex = 0;
SceneList scenes;
VisualizerManager visualizerManager;
MusicDataProvider provider;
Recorder recorder;

//
// Methods
//

float getSecondPerFrame()
{
  return (float)1.0 / fps;
}

SceneInfo getCurrentScene()
{
  return scenes.get(currentSceneIndex);
}

void loadSetting()
{
  XML scenesDefinition = loadXML("setting.xml");
  for (XML child : scenesDefinition.getChildren()) {
    String elementName = child.getName(); 
    if (elementName.equals("visualizers")) {
      visualizerManager = new VisualizerManager(child);
    }
    else if (elementName.equals("scenes")) {
      scenes = new SceneList(child);
    }
  }
}

void playNewSound()
{
  SceneInfo scene = getCurrentScene();
  visualizerManager.setupVisualizers(scene);

  provider = new MusicDataProvider(this, scene.filePath, scene.beatPerMinute);
  provider.play();
}
 
//
// Entry
//

void setup()
{
//size(640, 360, P3D);
//size(960, 540, P3D);
  size(1280, 720, P3D);

  loadSetting();

  smooth();
  frameRate(fps);

  if (recordFrame) {
    recorder = new FrameRecorder();
  //recorder = new VideoExportRecorder(this);
  //recorder = new AsyncFrameRecorder(this);
  }
  if (standby == false) {
    playNewSound();
  }
}

void stop()
{
  super.stop();

  if (provider != null) {
    provider.stop();
  }
  if (recorder != null) {
    recorder.finish();
    recorder = null;
  }
}

void draw()
{
  if (standby) {
    colorMode(HSB, 360, 0, 0, 0);
    background(360 * sin(map(frameCount % (frameRate * 8), 0, frameRate * 8, -PI, PI)));
    return;
  }

  if (provider.player.isPlaying() == false && provider.paused() == false) {
    if (recordSceneLastFrame) {
      saveFrame("SceneLast-########.png");
    }
    ++currentSceneIndex;
    if (scenes.scenes.size() <= currentSceneIndex) {
      if (scenes.repeatPlayback == false) {
        if (provider != null) {
          provider.stop();
        }
        if (recorder != null) {
          recorder.finish();
          recorder = null;
        }
        exit();
        return;
      }
      currentSceneIndex = 0;
    }
    playNewSound();
  }
  
  provider.update();
  visualizerManager.visualize(provider);
  
  if (recorder != null) {
    recorder.recordFrame();
  }
}

void keyReleased()
{
  switch (keyCode) {
    case ' ':
      if (standby) {
        standby = false;
        playNewSound();
      }
      else {
        if (provider.player.isPlaying()) {
          provider.pause();
        }
        else if (provider.paused()) {
          provider.play();
        }
      }
      break;
    default:
      visualizerManager.keyReleased();
      break;
  }
}

void mouseReleased()
{
    if (standby) {
      standby = false;
      playNewSound();
    }
    visualizerManager.mouseReleased();
}