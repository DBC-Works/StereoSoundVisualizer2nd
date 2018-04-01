/**
 * StereoSoundVisualizer2nd
 * for Processing 3.x
 * licensed under <a href="http://opensource.org/licenses/MIT">MIT License</a>
 * @author Sad Juno
 * @version 201803
 * @see <a href="https://github.com/DBC-Works">GitHub</a>
 */

//
// Settings
//

// screenScale: 0.75 - 960x540 / 1.0 - HD(1280x720) / 1.5 - Full HD(1920x1080)
final float screenScale = 4 / 4.0;

// fps: Frame per second
final int fps = 24;

// recorderType: frame recorder type
//final FrameRecorderType recorderType = FrameRecorderType.AsyncRecorder;
final FrameRecorderType recorderType = null;

// recordSceneLastFrame: Record last frame of scene
final boolean recordSceneLastFrame = false;

// standby: Start when space key is pressed
boolean standby = false;

//
// Classes
//


//
// Fields
//

ScreenCoordinator screenCoordinator = new ScreenCoordinator(screenScale);
int currentSceneIndex = 0;
int frameDropCount = 0;
SceneList scenes;
VisualizerManager visualizerManager;
MusicDataProvider provider;
FrameRecorder recorder;

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

  provider = new MusicDataProvider(this, scene.filePath, fps, scene.beatPerMinute);
  provider.play();
}

void tearDown()
{
  if (provider != null) {
    provider.stop();
  }
  if (recorder != null) {
    recorder.finish();
    recorder = null;
  }
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
  println("ms per frame: " + (getSecondPerFrame() * 1000) + "ms");

  if (recorderType != null) {
    recorder = createFrameRecorderInstanceOf(recorderType);
  }
  if (standby == false) {
    playNewSound();
  }
}

void draw()
{
  if (standby) {
    colorMode(HSB, 360, 0, 0, 0);
    background(360 * sin(map(frameCount % (frameRate * 8), 0, frameRate * 8, -PI, PI)));
    return;
  }

  long startTime = System.currentTimeMillis();
  if (provider.player.isPlaying() == false && provider.paused() == false) {
    if (recordSceneLastFrame) {
      saveFrame("img/SceneLast-########.png");
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
        if (0 < frameDropCount) {
          println("Frame drop count: " + frameDropCount + " / " + frameCount + "(" + (frameDropCount * 100.0 / frameCount) + ")");
        }
        tearDown();
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

  long timeTaken = System.currentTimeMillis() - startTime;
  if (((1.0 / frameRate) * 1000) < timeTaken) {
    println("Overtime: " + timeTaken + "ms(" + frameCount + ")");
    ++frameDropCount;
  }
}

void keyReleased()
{
  //println(keyCode);
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
 /*
    case 16:
      // PgUp
      --currentSceneIndex;
      if (currentSceneIndex < 0) {
        currentSceneIndex = scenes.scenes.size() - 1;
      }
      break;
    case 11:
      // PgDown
      ++currentSceneIndex;
      if (scenes.scenes.size() <= currentSceneIndex) {
        currentSceneIndex = 0;
      }
      break;
*/
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
