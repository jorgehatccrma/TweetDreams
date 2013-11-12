import processing.core.*;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.TreeSet;
import java.util.Vector;
import java.util.Random;
import java.util.Hashtable;
import java.util.concurrent.ConcurrentHashMap;
import java.awt.Color;
import processing.opengl.*;
import traer.physics.*;
import oscP5.*;
import netP5.*;

public class Twt extends PApplet{

	// STATIC ATTRIBUTES & METHODS
	private static final long serialVersionUID = 1L;

	public float minTextSize = 50;
	public float textSize = minTextSize;
	public Vector3D gravity = new Vector3D(0.0f, 0.0f, 0.0f);
	public float drag = 4000; //2000.0f;
	public float node_mass = 1000.0f;
	public float root_mass = 11000.0f;
	public float tree_spring_k = 200; //20f; //100f;		// srping's k constant
	public float tree_spring_dampening = 10.0f;		// spring's damping factor
	public float tree_spring_length = 5; //20; //40; //100f;		// spring's rest length
	public float tree_attraction_distance = 20f;
	public float tree_attraction = -10f;
	public float angleX = 0;
	public float angleX_target = 0;
	public float angleX_target_delta = 0;
	public float angleY = 0;
	public float angleY_target = 0;
	public float angleY_target_delta = 0;
	public float global_attraction = -500f;
	public float global_attraction_distance = 10f;
	public float root_spring_k = 500; //100f; //2000f;
	public float root_spring_dampening = 15000f;
	public float root_spring_length = 50f;
	public float root_attraction = -10f;
	public float root_attraction_distance = 10f;
	public float z_random_pos = 500;//0f;

	public float y_rotational_speed = 0;
	public float x_rotational_speed = 0;

	private float initial_zoom = 2500.0f;

	private int search_terms_font_size = 5;
	protected float new_tweets_stack_font_size = 2.5f;

	private boolean display_tweet_stack = true;

	public Vector3D camera;
	public Vector3D camera_target;
	public Vector3D camera_target_delta;
	public float slew = 0.2f;

	// camera params
	private float fov = PI/3f;
	private float aspect_ratio = 1; // must be changed when specifying the dimensions of the app
	private float distance_from_panel_to_camera = 100;

	private boolean animate_camera = true;
	private MidiManager midi_manager;

	private Particle invisible_center;

	private Random RandomIntGen = new Random();

	private boolean auto_animate = true;
	private boolean vertical_term_list = false;

	// Hack
  private static Hashtable<String,String> params = new Hashtable<String,String>();

	// INSTANCE ATTRIBUTES & METHODS
	OscP5 oscP5;

	Color stack_color = new Color(Colors.keywordTweetColor.getRed(), Colors.keywordTweetColor.getGreen(), Colors.keywordTweetColor.getBlue(), 127);

	IncomingStack local_incoming_stack = new IncomingStack( this, stack_color );

	// global attributes
	PFont tweet_font;
	PFont track_terms_font;
	PFont stack_font;
	String twt_keyword = "slork";
	public ParticleSystem particle_system = new ParticleSystem();

	ConcurrentHashMap<String, Tweet> tweetMap = new ConcurrentHashMap<String, Tweet>();
	Vector<Link> links = new Vector<Link>();
	ConcurrentHashMap<String, ArrayList<Tweet>> trees = new ConcurrentHashMap<String, ArrayList<Tweet>>();

	TreeSet<String> track_terms = new TreeSet<String>();
	TreeSet<String> keywords = new TreeSet<String>();

	Vector<Spring> root_springs = new Vector<Spring>();
	Vector<Spring> tree_springs = new Vector<Spring>();
	Vector<Attraction> root_attractions = new Vector<Attraction>();
	Vector<Attraction> tree_attractions = new Vector<Attraction>();
	Vector<Attraction> global_attractions = new Vector<Attraction>();

	int tracer_alpha = 200; // range: 0 (no decay) - 255 (immediate)


	public void setup() {

		// SYSTEM SPECIFIC HINTS
		hint( ENABLE_NATIVE_FONTS );
		hint( DISABLE_DEPTH_TEST );
		hint( ENABLE_OPENGL_4X_SMOOTH );


    // if (args.length >= 2) {
    //   size(Integer.parseInt(args[0]), Integer.parseInt(args[1]), OPENGL);
    // } else {
  		//size(1024, 768);
  		//size(1920, 1080, OPENGL);
  		//size(1024, 768, OPENGL);
  		//size(800, 600, OPENGL);
  		//size(1200, 300, OPENGL);
  		//size(1280, 800, OPENGL);
  		//size(1280, 768, OPENGL);
  		//size(1680, 1050, OPENGL);
  		//triplehead
  		//size(1920, 1080, OPENGL);
  		//size(2400, 600, OPENGL);
    // }

		size(Integer.parseInt(param("width")), Integer.parseInt(param("height")), OPENGL);


		//Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
	    //size(screen.width,screen.height,OPENGL);
		smooth();
		noCursor();
		frameRate(30);
		// start oscP5, listening for incoming messages at port whatever
		oscP5 = new OscP5(this,8891);

		setupPhysics();

		// setup MIDI surface
		// TODO: implement a way to select the correct midi device (for now we
		// are assuming there's only one device connected to the computer)
		// midi_manager = new MidiManager(this, MidiManager.MAUDIO_TRIGGER_FINGER, 0);
		midi_manager = new MidiManager(this, MidiManager.KORG_NANO_KONTROL, 0);
		// midi_manager = new MidiManager(this, MidiManager.BEHRINGER_BCR2000, 0);


		camera = new Vector3D(width/2.0f, height/2.0f, initial_zoom);
		camera_target = new Vector3D(camera);
		camera_target_delta = new Vector3D(0, 0, 0);

		// load and set the font
		tweet_font = createFont("arial.ttf", textSize);
		//track_terms_font = createFont("GeometricBlack.ttf", textSize);
		track_terms_font = createFont("Arial Bold.ttf", textSize);
		stack_font = createFont("Trebuchet MS.ttf", textSize);
		textFont(tweet_font);
		textAlign(LEFT);
		noStroke();
		noFill();
		smooth();
		background(0);

		aspect_ratio = (float)width/(float)height;
		// TODO: make perspective controllable in real-time
		// TODO: set a reasonable value for farZ (it could make things run faster)
		perspective(fov, aspect_ratio, 1f, 100000f);

		//keywords.add("#TweetDreams");
		//track_terms.add("music");
	}

	private void setupPhysics() {
		particle_system.setGravity(gravity.x(), gravity.y(), gravity.z());
		particle_system.setDrag(drag);

		invisible_center = particle_system.makeParticle(1.0f, width/2, height/2, 0.0f);
		invisible_center.makeFixed();

	}

  public static void println(java.lang.String what) {
	  PApplet.println("[Twt visualizer] " + what);
	}

	@Override
	public void keyPressed() {
		super.keyPressed();
		switch(key) {
		case 'w':
		case 'W':
			angleX_target_delta = -0.005f;
			break;
		case 's':
		case 'S':
			angleX_target_delta = 0.005f;
			break;
		case 'a':
		case 'A':
			angleY_target_delta = -0.005f;
			break;
		case 'd':
		case 'D':
			angleY_target_delta = 0.005f;
			break;
		case 'i':
		case 'I':
			camera_target_delta = new Vector3D(0, 0, -10);
			break;
		case 'o':
		case 'O':
			camera_target_delta = new Vector3D(0, 0, 10);
			break;
		case '/':
		case '?':
			//display_tweet_stack = !display_tweet_stack;
			display_tweet_stack = false;
			break;
		/*
		// the next case is to test without the rest of the system.
		// Comment out before compiling a final version
		case 'n':
		case 'N':
			int id = RandomIntGen.nextInt(10000);
			int neighbor = RandomIntGen.nextInt(10000);
			handleNewTweet(Integer.toString(id), Integer.toString(neighbor), 1.0f, "Test tweet with some random text", 1);
			break;
		*/
		}
	}

	@Override
	public void keyReleased() {
		super.keyReleased();
		switch(key) {
		case 'w':
		case 'W':
		case 's':
		case 'S':
			angleX_target_delta = 0f;
			break;
		case 'a':
		case 'A':
		case 'd':
		case 'D':
			angleY_target_delta = 0f;
			break;
		case 'i':
		case 'I':
		case 'o':
		case 'O':
			camera_target_delta = new Vector3D(0, 0, 0);
			break;
		}
	}

	private void drawPanel() {
		// This "panel" fills the entire screen, independently of the camera position

		float margin = 2;

		noStroke();
		// TODO: make the background color change slowly between different dark colors
		fill(0, 0, 0, tracer_alpha);
		//fill(30, 30, 30, 80);

		float rect_height = 2f*(distance_from_panel_to_camera)*tan(fov/2);
		float rect_width = rect_height * aspect_ratio;

		float dx = rect_width/2f - width/2f;
		float dy = rect_height/2f - height/2f;
		//println( rect_width + " " + dx + " " + rect_height + " " + dy );


		pushMatrix();
		translate(0, 0, camera.z() - distance_from_panel_to_camera);

		// draw a rectangle filling the entire visual screen
		//rect(-dx, -dy, rect_width, rect_height );
		// OpenGL version with gradient
		beginShape(QUADS);
		fill(Colors.background_top.getRed(), Colors.background_top.getGreen(), Colors.background_top.getBlue(), tracer_alpha);
		vertex(-dx,-dy);
		vertex(rect_width-dx,-dy);
		fill(Colors.background_bottom.getRed(), Colors.background_bottom.getGreen(), Colors.background_bottom.getBlue(), tracer_alpha);
		vertex(rect_width-dx, rect_height-dy);
		vertex(-dx, rect_height-dy);
		endShape();

		// show track terms in the screen
		displayTrackTerms(-dx+margin, -dy+margin, rect_width-dx);

		// show the incoming tweets
		if(display_tweet_stack)
			local_incoming_stack.draw(rect_width-2*margin, rect_height-2*margin, rect_width-dx-margin, rect_height-dy-margin);

		popMatrix();
	}


	private void displayTrackTerms(float x_offset, float y_offset, float rect_width) {

		textFont(track_terms_font);
		textSize(search_terms_font_size);
		textAlign(LEFT);
		y_offset += textAscent() + textDescent();
		int alpha = 225;
		float z_pos = 0;
		float x_offset_orig = x_offset;

		fill(Colors.keywordTweetColor.getRGB(), alpha);
		synchronized(keywords) {
			Iterator<String> it = keywords.iterator();
			while (it.hasNext()) {
				String term = it.next();
				if (!vertical_term_list & ((x_offset+textWidth(term)) > rect_width) ) {
          y_offset += textAscent() + textDescent();
          x_offset = x_offset_orig;
				}
				text(term, x_offset, y_offset, z_pos);
				if (vertical_term_list) {
          y_offset += textAscent() + textDescent();
				} else {
          x_offset += textWidth(term+" ");
				}
			}
		}

		fill(Colors.newTweetColor.getRGB(), alpha);
		synchronized (track_terms) {
			Iterator<String> it = track_terms.iterator();
			while (it.hasNext()) {
				String term = it.next();
				if (!vertical_term_list & ((x_offset+textWidth(term)) > rect_width) ) {
          y_offset += textAscent() + textDescent();
          x_offset = x_offset_orig;
				}
				text(term, x_offset, y_offset, z_pos);
				if (vertical_term_list) {
          y_offset += textAscent() + textDescent();
				} else {
          x_offset += textWidth(term+" ");
				}
			}
		}
	}

	public void autoAnimation() {
		angleY_target_delta = y_rotational_speed; //0.0023f;
		angleX_target_delta = x_rotational_speed; //0.0061f;
	}

	public void draw() {

		if( auto_animate ) autoAnimation();

		// draw panel that displays the keyword, search terms and incomming tweets stack
		drawPanel();

		// interpolate parameters
		slewParams();

		// place the camera
		camera(	camera.x(), camera.y(), camera.z(),
				width/2.0f, height/2.0f, 0.0f,
				0.0f, 1.0f, 0.0f );

		// advance the physics simulation
		try {
			particle_system.tick();
		} catch (Exception e) {
			println("physics engine exception raised!");
			//e.printStackTrace();
		}

		if(animate_camera) {
			pushMatrix();
			translate(width/2, 0, 0);
			rotateY(angleY);
			translate(-width/2, 0, 0);
			translate(0, height/2, 0);
			rotateX(angleX);
			translate(0, -height/2, 0);
		}


		// Draw links
		synchronized(links) {
			Iterator<Link> lit = links.iterator();
			while(lit.hasNext()) {
				lit.next().draw();
			}
		}

		// Draw nodes
		Iterator<Tweet> it = tweetMap.values().iterator();
		while(it.hasNext()) {
			it.next().draw();
		}

		if(animate_camera) {
			popMatrix();
		}

	}

	private void slewParams() {

		angleX_target += angleX_target_delta;
		angleY_target += angleY_target_delta;
		camera_target.add(camera_target_delta);

		camera.setX( (camera_target.x() - camera.x()) * slew + camera.x() );
		camera.setY( (camera_target.y() - camera.y()) * slew + camera.y() );
		camera.setZ( (camera_target.z() - camera.z()) * slew + camera.z() );

		// prevent camera reversal (processing+OpenGL bug?)
		if ( camera.z() < distance_from_panel_to_camera ) camera.setZ( distance_from_panel_to_camera );

		angleX = (angleX_target - angleX) * slew + angleX;
		angleY = (angleY_target - angleY) * slew + angleY;

	}

	public void oscEvent(OscMessage theOscMessage) {

		//println("Incoming OSC message: " + theOscMessage.addrPattern() + " (" + theOscMessage.typetag() + ")");

		try {
			/* check if theOscMessage has the address pattern we are looking for. */
			if(theOscMessage.checkAddrPattern("/twt/newNode")) {
				if(theOscMessage.checkTypetag("ssfsi")) {
					String id = theOscMessage.get(0).stringValue();  // nodeID
					String neighbor_id = theOscMessage.get(1).stringValue();  // neighbor_id ID
					float distance = theOscMessage.get(2).floatValue(); // distance to neighbor (not using)
					String twt_text = theOscMessage.get(3).stringValue(); // the actual tweet string
					int is_local = theOscMessage.get(4).intValue();

					handleNewTweet(id, neighbor_id, distance, twt_text, is_local);

					return;
				}
			} else if(theOscMessage.checkAddrPattern("/twt/triggerNode")) {
				if(theOscMessage.checkTypetag("isfi")) {
					int echoID = theOscMessage.get(0).intValue();
					String nodeID = theOscMessage.get(1).stringValue();
					float del = theOscMessage.get(2).floatValue();
					int hopLevel = theOscMessage.get(3).intValue();

          // println(hopLevel+","+echoID+","+nodeID+","+del);
					handleTrigger(echoID, nodeID, del, hopLevel);

					return;
				}
			} else if(theOscMessage.checkAddrPattern("/twt/addTerm")) {
				if(theOscMessage.checkTypetag("s")) {
					String term = theOscMessage.get(0).stringValue();
					println("Adding '" + term + "' to the track term list");
					track_terms.add(term);
					return;
				}
			} else if(theOscMessage.checkAddrPattern("/twt/removeTerm")) {
				if(theOscMessage.checkTypetag("s")) {
					String term = theOscMessage.get(0).stringValue();
					println("Removing '" + term + "' from the track term list");
					if(track_terms.contains(term))
						track_terms.remove(term);
					return;
				}
			} else if(theOscMessage.checkAddrPattern("/twt/keyword")) {
				if(theOscMessage.checkTypetag("s")) {
					String term = theOscMessage.get(0).stringValue();
					println("Adding '" + term + "' to the keywords list");
					keywords.add(term);
					return;
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private void handleNewTweet(String id, String neighbor_id, float distance, String twt_text, int is_local) {
		//Particle p = particle_system.makeParticle(node_mass, random(0, width/4), random(height/4, (3*height/4)), random(-10,10) );
		//Particle p = particle_system.makeParticle(node_mass, random(-width/1.5f, width*1.3f), random(-height/2, height), random(-100,100) );

		float zoom_factor = camera_target.z()/initial_zoom;

		Particle p = particle_system.makeParticle(node_mass/(neighbor.level + 1),
				zoom_factor*random(-width/1.5f, width*1.3f),
				zoom_factor*random(-height/2, height),
				zoom_factor*random(-z_random_pos,z_random_pos) );
		Tweet tweet = new Tweet(this, twt_text, p, is_local, 1);
		tweetMap.put(id,tweet);
		Tweet neighbor = null;
		if(tweetMap.containsKey(neighbor_id)) {
			neighbor = tweetMap.get(neighbor_id);
			tweet.level = neighbor.level + 1;
			p.setMass( node_mass * (float)tweet.level );
			tweet.setRoot(neighbor.tree_root_node);
			tweet.copyColors(neighbor);
			Spring spring = particle_system.makeSpring(	tweet.particle, neighbor.particle,
					tree_spring_k / (float)tweet.level, tree_spring_dampening, tree_spring_length );
			tree_springs.add(spring);
			links.add(new Link(tweet, neighbor, distance, this, spring));
			addTweetToTree(tweet, neighbor);
			Iterator<Tweet> it = tweetMap.values().iterator();
			while(it.hasNext()) {
				Tweet t = it.next();
				if(!t.is_root && !t.tree_root_node.equals(tweet.tree_root_node))
					global_attractions.add(particle_system.makeAttraction(tweet.particle, t.particle, global_attraction, global_attraction_distance));
			}
		} else {
			tweet.makeRoot();
			root_springs.add(particle_system.makeSpring(invisible_center, tweet.particle, root_spring_k, root_spring_dampening, root_spring_length));
			Iterator<Tweet> it = tweetMap.values().iterator();
			while(it.hasNext()) {
				Tweet t = it.next();
				if(t.is_root)
					root_attractions.add(particle_system.makeAttraction(tweet.particle, t.particle, root_attraction, root_attraction_distance));
			}
			createNewTree(id, tweet);
		}

		// add the tweet to the new_tweets_stack, for the initial display
		if(tweet.is_local) local_incoming_stack.addTweet( tweet );

	}

	private void addTweetToTree(Tweet tweet, Tweet 	neighbor) {
		tweet.setTreeRoot(neighbor.getTreeRoot());
		ArrayList<Tweet> tree = trees.get(neighbor.getTreeRoot());
		Iterator<Tweet> it = tree.iterator();
		while(it.hasNext()) {
			Tweet t = it.next();
			tree_attractions.add(particle_system.makeAttraction(tweet.particle, t.particle, tree_attraction, tree_attraction_distance));
		}
		tree.add(tweet);
	}

	private void createNewTree(String id, Tweet root) {
		root.setTreeRoot(id);
		root.particle.setMass(root_mass);
		ArrayList<Tweet> arr = new ArrayList<Tweet>();
		arr.add(root);
		trees.put(id, arr);
	}

	private void handleTrigger(int echoID, String nodeID, float del, int hopLevel) {
		if(tweetMap.containsKey(nodeID)) {
			Tweet node = (Tweet)(tweetMap.get(nodeID));
			node.highlight(hopLevel+1);
		} else {
			println("Trying to trigger a node that doesn't exist! (nodeID = " + nodeID + ")");
		}
	}

	// root parameters

	public void updateRootSpringLength() {
		Iterator<Spring> it = root_springs.iterator();
		while(it.hasNext()) {
			it.next().setRestLength(root_spring_length);
		}
	}

	public void updateRootSpringK() {
		Iterator<Spring> it = root_springs.iterator();
		while(it.hasNext()) {
			it.next().setStrength(root_spring_k);
		}
	}

	public void updateRootDampening() {
		Iterator<Spring> it = root_springs.iterator();
		while(it.hasNext()) {
			it.next().setDamping(root_spring_dampening);
		}
	}

	public void updateRootAttraction() {
		Iterator<Attraction> it = root_attractions.iterator();
		while(it.hasNext()) {
			it.next().setStrength(root_attraction);
		}
	}

	// tree parameters

	public void updateTreeSpringLength() {
		Iterator<Spring> it = tree_springs.iterator();
		while(it.hasNext()) {
			it.next().setRestLength(tree_spring_length);
		}
	}

	public void updateTreeSpringK() {
		Iterator<Spring> it = tree_springs.iterator();
		while(it.hasNext()) {
			it.next().setStrength(tree_spring_k);
		}
	}

	public void updateTreeSpringDampening() {
		Iterator<Spring> it = tree_springs.iterator();
		while(it.hasNext()) {
			it.next().setStrength(tree_spring_dampening);
		}
	}

	public void updateTreeAttraction() {
		Iterator<Attraction> it = tree_attractions.iterator();
		while(it.hasNext()) {
			it.next().setStrength(tree_attraction);
		}
	}

  // overwrite the default param() function
  // if we're not online (i.e. running as application), the new function
  // will use the Hashtable to find the param
  public String param(String id) {
    if (online) return super.param(id);
    else return (String)params.get(id);
  }

	// adds Java Application output, "--present" is full screen mode
	public static void main(String args[])
	{
    // we'll read the app's width and height from command line args.
    // See: http://wiki.processing.org/w/Setting_width/height_dynamically
    // The command lines must be in the following form:
    // >> java Twt width=800 height=600

    String[] newArgs = new String[args.length+5];
    int i;
    for(i=0; i<args.length; i++) {
      newArgs[i]=args[i];
      if (args[i].indexOf("=")!=-1) {
        String[] pair=split(args[i], '=');
        params.put(pair[0],pair[1]);
      }
    }
    newArgs[i+0] = "--hide-stop";
    newArgs[i+1] = "--display=1";
    newArgs[i+2] = "--present";
    //newArgs[i+3] = "--bgcolor=#CD2824";
    newArgs[i+3] = "--bgcolor=#000000";
    // newArgs[i+3] = "--bgcolor=#FFFFFF";
    newArgs[i+4] = Twt.class.getName();

    // apply default width and height if necessary
    if (!params.containsKey("width")) {
      params.put("width","800");
    }
    if (!params.containsKey("height")) {
      params.put("height","600");
    }

    // pass on to PApplet entry point
    PApplet.main(newArgs);

	}


}
