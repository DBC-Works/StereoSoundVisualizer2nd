/**
 * Particle
 * @author Sad Juno
 * @version 201605
 */
 

final class Particle
{
  private final List<PVector> positions = new ArrayList<PVector>();
  private final int historyCount;
  private int aliveCount;
  private boolean terminated;
  
  Particle(PVector pos, int count)
  {
    positions.add(pos.get());
    historyCount = count;
  }

  PVector getCurrentPosition()
  {
    return positions.get(positions.size() - 1).get();
  }
  List<PVector> getPositionHistory()
  {
    return Collections.unmodifiableList(positions);
  }
  int getAliveCount()
  {
    return aliveCount;
  }
  boolean isAlive()
  {
    return terminated == false || positions.isEmpty() == false;
  }
  
  void terminate()
  {
    terminated = true;
  }
  void moveTo(PVector pos)  
  {
    ++aliveCount;
    if (terminated == false) {
      positions.add(pos);
    }
    if (historyCount < positions.size() || (terminated && positions.isEmpty() == false)) {
      positions.remove(0);
    }
  }
}