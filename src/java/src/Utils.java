import processing.core.PMatrix3D;
import processing.core.PVector;
import traer.physics.Vector3D;

public class Utils {

	// TODO: finish implementing. I need to understand what does the (source, target) arguments
	// mean in the .mult method
	/**
	 * Constructor for translation (rotate) method
	 * 
	 * @param vector  
	 * @param about
	 * @param angle
	 * @return
	 */
	static public PVector rotate(PVector vector, PVector about, float angle) {
		
		PMatrix3D rx = new PMatrix3D(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
		PVector out = rx.mult(vector, vector); // what does the second argument mean (target)?
		return out;
	}
	
	/**
	 * Translation methods for rotation
	 * 
	 * Processing (PVector) 
	 * 
	 * @param vec : 
	 * @param angle : rotation angle in radians
	 * @return
	 */
	static public PVector rotate2D ( PVector vec, float angle ) {
		float c = (float)Math.cos(angle);
		float s = (float)Math.sin(angle);
		return new PVector( vec.x*c - vec.y*s, 
							vec.x*s + vec.y*c );
	}
	

	static public Vector3D rotate2D ( Vector3D vec, float angle ) {
		float c = (float)Math.cos(angle);
		float s = (float)Math.sin(angle);
		return new Vector3D( vec.x()*c - vec.y()*s, 
							vec.x()*s + vec.y()*c, 
							0 );
	}
	
}
