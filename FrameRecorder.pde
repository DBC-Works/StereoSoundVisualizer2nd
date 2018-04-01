/**
 * FrameRecorder
 * for Processing 3.x
 * licensed under <a href="http://opensource.org/licenses/MIT">MIT License</a>
 * @author Sad Juno
 * @version 201803
 * @see <a href="https://github.com/DBC-Works">GitHub</a>
 */

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
// if you want to use <a href="https://www.funprogramming.org/VideoExport-for-Processing/">Video Export</a>,
// delete comment after this comment.
//import com.hamoid.*;

interface FrameRecorder
{
  abstract void recordFrame();
  abstract void finish();
}

final class SyncFrameRecorder implements FrameRecorder
{
  SyncFrameRecorder()
  {
  }

  void recordFrame()
  {
    saveFrame("img/########.tga");
  }
  
  void finish()
  {
  } 
}

final class AsyncFrameRecorder implements FrameRecorder
{
  private final ExecutorService executor = Executors.newCachedThreadPool();
  private final List<Future> futures = new ArrayList<Future>();
  
  AsyncFrameRecorder()
  {
  }

  void recordFrame()
  {
    if (executor.isShutdown()) {
      return;
    }

    loadPixels();

    final int[] savePixels = Arrays.copyOf(pixels, pixels.length);
    final long saveFrameCount = frameCount;
    Runnable saveTask = new Runnable() {
      public void run() {
        final PImage frameImage = createImage(width, height, HSB);
        frameImage.pixels = savePixels;
        frameImage.save(String.format("img/%08d.jpg", saveFrameCount));
      }
    };
    
    Iterator<Future> it = futures.iterator();
    while (it.hasNext()) {
      Future f = it.next();
      if (f.isDone()) {
        it.remove();
      }
    }
    futures.add(executor.submit(saveTask));
  }
  
  void finish()
  {
    try {
      Thread.sleep(1000);
    }
    catch (InterruptedException e) {
    }
    
    for (Future f : futures) {
      if (f.isDone() == false && f.isCancelled() == false) {
        try {
          f.get();
        }
        catch (InterruptedException e) {
        }
        catch (ExecutionException e) {
        }
      }
    }
    if (executor.isShutdown() == false) {
      executor.shutdown();
      try {
        if (executor.awaitTermination(5, TimeUnit.SECONDS) == false) {
          executor.shutdownNow();
          executor.awaitTermination(5, TimeUnit.SECONDS);
        }
      }
      catch (InterruptedException e) {
        executor.shutdownNow();
      }
    }
  }
}

/*
final class VideoExportRecorder implements FrameRecorder
{
  private final VideoExport videoExport;
  
  VideoExportRecorder(PApplet applet)
  {
    videoExport = new VideoExport(applet, "movie.mp4");
    videoExport.startMovie();
  }

  void recordFrame()
  {
    videoExport.saveFrame();
  }
  
  void finish()
  {
    videoExport.endMovie();
  }
}
 */

enum FrameRecorderType {
  //VideoExportRecorder,
  SyncRecorder,
  AsyncRecorder
}

FrameRecorder createFrameRecorderInstanceOf(FrameRecorderType type)
{
  switch (type) {
    /*
    case VideoExportRecorder:
      return new VideoExportRecorder(this);
     */
    case SyncRecorder:
      return new SyncFrameRecorder();
    case AsyncRecorder:
      return new AsyncFrameRecorder();
    default:
      throw new RuntimeException();
  }
}
