import java.util.HashMap;

import javax.sound.midi.*;
public class MidiManager {

	public static final int AKAI_MPD24 = 0;
	public static final int MAUDIO_TRIGGER_FINGER = 1;
	public static final int KORG_NANO_KONTROL = 2;
	public static final int BEHRINGER_BCR2000 = 3;

	private static final int GRAVITY_X = 0;
	private static final int GRAVITY_Y = 1;
	private static final int GRAVITY_Z = 2;
	private static final int CAM_ROTATE_X = 3;
	private static final int CAM_ROTATE_Y = 4;
	private static final int CAM_ZOOM = 5;
	private static final int TREE_SPRING_K = 6;
	private static final int TREE_SPRING_DAMPENING = 7;
	private static final int TREE_SPRING_LENGTH = 8;
	private static final int TREE_ATTRACTION = 9;
	private static final int TREE_ATTRACTION_DISTANCE = 10;
	private static final int DRAG = 11;
	private static final int NODE_MASS = 12;
	private static final int ROOT_MASS = 13;
	private static final int GLOBAL_ATTRACTION = 14;
	private static final int GLOBAL_ATTRACTION_DISTANCE = 15;
	private static final int ROOT_SPRING_K = 16;
	private static final int ROOT_SPRING_DAMPENING = 17;
	private static final int ROOT_SPRING_LENGTH = 18;
	private static final int ROOT_ATTRACTION = 19;
	private static final int ROOT_ATTRACTION_DISTANCE = 20;
	private static final int TRACER = 500;
	private static final int TEXT_SIZE = 22;
	private static final int Z_RANDOM = 23;
	private static final int Y_ROTATION_SPEED = 24;
	private static final int X_ROTATION_SPEED = 25;

	private Twt parent;
	private Transmitter transmitter;
	private Receiver receiver;
	private int surface;

	private HashMap<Integer, HashMap<Integer, Integer> > mappings;

	/**
	 * Constructor for the MidiManager object.
	 *
	 * @param _parent    Parent class object import
	 * @param _surface   Controller specific mappings
	 * @param device_id  A sequential integer representing acquired MIDI devices
	 */
	public MidiManager(Twt _parent, int _surface, int device_id) {
		parent = _parent;
		surface = _surface;

		mappings = new HashMap<Integer, HashMap<Integer,Integer>>();

		populateMappings();
		connectMidi(device_id);
	}

	/**
	 * Connects to MIDI controller and sets up mappings.
	 *
	 * Scans for all available MIDI devices and opens a connection to one.  Sets up mappings from
	 * various control parameters to MIDI controller numbers.
	 *
	 * @param device_id  A sequential integer representing acquired MIDI devices
	 */
	private void connectMidi(int device_id) {
		try {
        	MidiDevice.Info[] midiDevices = MidiSystem.getMidiDeviceInfo();
        	//for(int i = 0; i < midiDevices.length; i++)
        	//	Twt.println(midiDevices[i].getVendor() + " " + midiDevices[i].getName() + " - " + midiDevices[i].getDescription());

        	if(device_id < midiDevices.length) {
        		Twt.println("Using " + midiDevices[device_id].getVendor() + " " + midiDevices[device_id].getName() );
        	} else {
        		Twt.println("The device_id " + device_id  + " exceeds the number of available MIDI devices (" + midiDevices.length  + ")");
        	}

        	MidiDevice midiDevice = MidiSystem.getMidiDevice(midiDevices[device_id]);
        	midiDevice.open();
        	transmitter = midiDevice.getTransmitter();
        	receiver = new Receiver() {
        		public void close(){};
        		public void send(MidiMessage mm, long ts) {
        			//System.out.Twt.println(mm.getStatus());
        			if(mm instanceof ShortMessage) {
        				ShortMessage sm = (ShortMessage)mm;
        				// Twt.println("channel: " + sm.getChannel() + "; command: " + sm.getCommand() + "; data1: " + sm.getData1() + "; data2: " + sm.getData2() + "; length: " + sm.getLength() + "; status: " + sm.getStatus() + "; message: " + sm.getMessage().toString());
        				int id = sm.getData1();
        				//Twt.println(id);
        				float value = (float)sm.getData2();
        				// Twt.println("value: "+value);
        				switch (mappings.get(surface).get(id)) {
						case MidiManager.GRAVITY_X:
							break;
						case MidiManager.GRAVITY_Y:
							float g = -100*(value - 64f);
							parent.particle_system.setGravity(0, g, 0);
							break;
						case MidiManager.GRAVITY_Z:
							break;
						case MidiManager.CAM_ROTATE_X:
							parent.angleX_target = Twt.TWO_PI*value/127;
							break;
						case MidiManager.CAM_ROTATE_Y:
							parent.angleY_target = Twt.TWO_PI*value/127;
							break;
						case MidiManager.CAM_ZOOM:
							parent.camera_target.setZ((127-value)*100);
							break;
						case MidiManager.TREE_SPRING_K:
							parent.tree_spring_k=value*1f;
							parent.updateTreeSpringK();
							break;
						case MidiManager.TREE_SPRING_DAMPENING:
							parent.tree_spring_dampening=value*10;
							parent.updateTreeSpringDampening();
							break;
						case MidiManager.TREE_SPRING_LENGTH:
							parent.tree_spring_length=value*10;
							parent.updateTreeSpringLength();
							break;
						case MidiManager.TREE_ATTRACTION:
							parent.tree_attraction=-value*2;
							parent.updateTreeAttraction();
							break;
						case MidiManager.TREE_ATTRACTION_DISTANCE:
							// not interesting
							break;
						case MidiManager.DRAG:
							float d = 10*value + 500f;
							parent.particle_system.setDrag(d);
							break;
						case MidiManager.NODE_MASS:
							break;
						case MidiManager.ROOT_MASS:
							break;
						case MidiManager.GLOBAL_ATTRACTION:
							break;
						case MidiManager.GLOBAL_ATTRACTION_DISTANCE:
							// not interesting
							break;
						case MidiManager.ROOT_SPRING_K:
							parent.root_spring_k=value*100;
							//Twt.println("root spring k: "+parent.root_spring_k);
							parent.updateRootSpringK();
							break;
						case MidiManager.ROOT_SPRING_DAMPENING:
							parent.root_spring_dampening=value*200;
							//Twt.println("root spring dampening: "+parent.root_spring_dampening);
							parent.updateRootDampening();
							break;
						case MidiManager.ROOT_SPRING_LENGTH:
							parent.root_spring_length=value*6;//value*12;
							//Twt.println("root spring length: "+parent.root_spring_length);
							parent.updateRootSpringLength();
							break;
						case MidiManager.ROOT_ATTRACTION:
							parent.root_attraction=value*-5 - 8;
							//Twt.println("root attraction: "+parent.root_attraction);
							parent.updateRootAttraction();
							break;
						case MidiManager.ROOT_ATTRACTION_DISTANCE:
							// not interesting
							break;
						case MidiManager.TRACER:
							parent.tracer_alpha = (int)(127-value)*2;
							break;
						case MidiManager.TEXT_SIZE:
							parent.textSize = parent.minTextSize + (int)value*2.5f;
							break;
						case MidiManager.Z_RANDOM:
							parent.z_random_pos = (int)value*10;
							//Twt.println("z_random_pos: "+parent.z_random_pos);
							break;
						case MidiManager.Y_ROTATION_SPEED:
							Twt.println("ppppp");
							parent.y_rotational_speed = ((int)value - 64 ) / 1000f;
							Twt.println("y_rotational_speed: "+parent.y_rotational_speed);
							break;
						case MidiManager.X_ROTATION_SPEED:
							Twt.println("ppppp");
							parent.x_rotational_speed = ((int)value - 64 ) / 1000f;
							Twt.println("x_rotational_speed: "+parent.x_rotational_speed);
							break;
						default:
							Twt.println("CONTROL NOT ASSIGNED");
							break;
						}
        			} else {
        				Twt.println("This is not a short midi message!");
        			}
        		}
        	};
        	transmitter.setReceiver(receiver);
		} catch (MidiUnavailableException e) {
			e.printStackTrace();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}


	/**
	 * Create HashMap of controller MIDI mappings for a specific controller
	 */
	private void populateMappings() {
		HashMap<Integer, Integer> map = new HashMap<Integer, Integer>();
		// AKAI_MPD24 mappings
		map.put(16, MidiManager.GRAVITY_Y);
		map.put(17, MidiManager.CAM_ROTATE_Y);
		map.put(18, -1);
		map.put(19, -1);
		map.put(4, -1);
		map.put(7, -1);
		map.put(82, -1);
		map.put(77, -1);
		map.put(61, -1);
		map.put(72, -1);
		map.put(56, -1);
		map.put(35, -1);
		map.put(51, -1);
		map.put(41, -1);
		mappings.put(MidiManager.AKAI_MPD24, map);

		// M-AUDIO TRIGGER FINGER mappings
		map = new HashMap<Integer, Integer>();
		map.put(0, MidiManager.GRAVITY_Y);
		map.put(1, MidiManager.CAM_ROTATE_X);
		map.put(7, MidiManager.CAM_ROTATE_Y);
		map.put(8, MidiManager.CAM_ZOOM);
		map.put(9, MidiManager.TRACER);
		map.put(13, MidiManager.Z_RANDOM);
		map.put(10, MidiManager.Y_ROTATION_SPEED);
		map.put(14, MidiManager.X_ROTATION_SPEED);
		map.put(11, -1);
		map.put(15, -1);
		map.put(12, -1);
		map.put(16, -1);
		mappings.put(MidiManager.MAUDIO_TRIGGER_FINGER, map);

		// KORG NANO CONTROL mappings
		// SCENE 1 (of 4)
		map =  new HashMap<Integer, Integer>();
		// knobs 1-9
		map.put(14, MidiManager.DRAG);
		map.put(15, MidiManager.TRACER);
		/*
		map.put(16, MidiManager.Z_RANDOM);
		map.put(17, MidiManager.CAM_ZOOM);
		map.put(18, MidiManager.Y_ROTATION_SPEED);
		map.put(19, MidiManager.X_ROTATION_SPEED);
		*/
		map.put(16, MidiManager.CAM_ZOOM);
		map.put(17, MidiManager.Y_ROTATION_SPEED);
		map.put(18, MidiManager.X_ROTATION_SPEED);
		// map.put(20, MidiManager.TREE_SPRING_DAMPENING);
		map.put(21, -1);
		map.put(22, -1);
		// sliders 1-9
		map.put(2, MidiManager.GRAVITY_Y);
		map.put(3, MidiManager.ROOT_SPRING_LENGTH);
		map.put(4, MidiManager.TREE_SPRING_LENGTH);
		map.put(5, MidiManager.TEXT_SIZE);
		map.put(6, -1);
		map.put(7, -1);
		map.put(8, -1);
		map.put(9, -1);
		// buttons a and b for (control groups) 1-9: a = upper button, b = lower button
		// buttons issue both press = 127 and release = 0 messages
		// control group 1 a
		map.put(23, -1);
		// control group 1 b
		map.put(33, -1);
		// control group 2 a b
		map.put(24, -1); // a
		map.put(34, -1); // b
		// 3
		map.put(25, -1); // a
		map.put(35, -1); // b
		// 4
		map.put(26, -1);
		map.put(36, -1);
		// 5
		map.put(27, -1);
		map.put(37, -1);
		// 6
		map.put(28, -1);
		map.put(38, -1);
		// 7
		map.put(29, -1);
		map.put(39, -1);
		// 8
		map.put(30, -1);
		map.put(40, -1);
		// 9
		map.put(31, -1);
		map.put(41, -1);

		mappings.put(MidiManager.KORG_NANO_KONTROL, map);

	// BEHRINGER BCR2000 mappings
	map =  new HashMap<Integer, Integer>();
	// knobs 1-9
	map.put(84, MidiManager.DRAG);
	map.put(87, MidiManager.TRACER);
	// map.put(16, MidiManager.ROOT_SPRING_K);
	// map.put(17, MidiManager.ROOT_SPRING_DAMPENING);
	map.put(18, -1);
	// map.put(19, MidiManager.TREE_SPRING_K);
	// map.put(20, MidiManager.TREE_SPRING_DAMPENING);
	map.put(21, -1);
	map.put(22, -1);
	// sliders 1-9
	map.put(81, MidiManager.GRAVITY_Y);
	map.put(82, MidiManager.ROOT_SPRING_LENGTH);
	map.put(83, MidiManager.TREE_SPRING_LENGTH);
	map.put(88, MidiManager.TEXT_SIZE);
	map.put(6, -1);
	map.put(7, -1);
	map.put(8, -1);
	map.put(9, -1);
	// buttons a and b for (control groups) 1-9: a = upper button, b = lower button
	// buttons issue both press = 127 and release = 0 messages
	// control group 1 a
	map.put(23, -1);
	// control group 1 b
	map.put(33, -1);
	// control group 2 a b
	map.put(24, -1); // a
	map.put(34, -1); // b
	// 3
	map.put(25, -1); // a
	map.put(35, -1); // b
	// 4
	map.put(26, -1);
	map.put(36, -1);
	// 5
	map.put(27, -1);
	map.put(37, -1);
	// 6
	map.put(28, -1);
	map.put(38, -1);
	// 7
	map.put(29, -1);
	map.put(39, -1);
	// 8
	map.put(30, -1);
	map.put(40, -1);
	// 9
	map.put(31, -1);
	map.put(41, -1);

	mappings.put(MidiManager.BEHRINGER_BCR2000, map);
}

}
