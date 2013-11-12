import java.awt.Color;
import java.util.Random;
import java.util.Vector;

import processing.core.*;

import megamu.shapetween.*;
import traer.physics.*;

/**
 *
 *
 * @author carrlane
 *
 */

public class Tweet {

	static float tau = 0.975f;
	static int max_fade_out_intensity = 255;

	Twt parent;	// the PApplet

	Vector<Link> links;

	public String the_tweet;
	public boolean is_local = false;
	public boolean is_newcommer = false;
	public int level = 1;

	private float dob;

	private boolean show_node = true;
	private boolean show_text = false;
	private boolean is_new = true;
	private boolean show_leaves = false;
	private float ellipse_width;
	private float ellipse_height;
	private float inclination;
	private float orbit_radius = 20;
	private float decay_rate = 0.9995f;//0.985f;
	private float global_alpha = 1.0f;
	private Tween fade_out;
	private int max_line_length = 20;
	private int fade_out_intensity = 0;
	private int hop_level = 1;
	private String[] words;
	private float[] word_angles;
	private float max_movement_allowed = 500f;
	private float newFadeOutTime = 6.5f;
	private float triggerFadeOutTime = 3f;

	protected Particle particle;
	protected Vector3D last_position;
	protected String tree_root_node;
	protected boolean is_root = false;

	private Color text_color;
	public Color node_fill_color;
	public Color node_stroke_color;
	public Color satellite_color;

	public Tweet(Twt p, String twt_text, Particle _particle, int _is_local, int _level) {

		parent = p;
		particle = _particle;
		last_position = new Vector3D(particle.position());
		links = new Vector<Link>();
		is_new = true;
		level = _level;

		// text handling
		the_tweet = twt_text;
		words = the_tweet.split("[ ]+");
		word_angles = new float[words.length];
		for(int i = 0; i < words.length; i++)
			word_angles[i] = parent.random(-Twt.PI, Twt.PI);

		if( _is_local == 1 ) {
			this.is_local = true;
			//this.is_newcommer = true;
		}

		// colors and other graphic parameters
		text_color = Colors.newTweetColor;
		//inclination = parent.random(-Twt.HALF_PI, Twt.HALF_PI);
		inclination = 0;
		ellipse_width = parent.random(10,20);
		ellipse_height = parent.random(10,20);

		node_fill_color = Colors.node_fill_color;
		node_stroke_color = Colors.node_stroke_color;
		satellite_color = Colors.satellite_color;

		// set "date of birth" of the tweet
		dob = parent.millis();

		setupAnimations();
	}

	public void makeRoot() {
		is_root = true;
		Random gen = new Random();

		int var = 50;

		int r = node_fill_color.getRed() + gen.nextInt( 2*var ) - var;
		int g = node_fill_color.getGreen() + gen.nextInt( 2*var ) - var;
		int b = node_fill_color.getBlue() + gen.nextInt( 2*var ) - var;
		int alpha = node_fill_color.getAlpha();

		if (r > 255) r = 255;
		if (r < 0) r = 0;
		if (g > 255) g = 255;
		if (g < 0) g = 0;
		if (b > 255) b = 255;
		if (b < 0) b = 0;

		node_fill_color = new Color( r, g, b, alpha );

		alpha = node_stroke_color.getAlpha();
		node_stroke_color = new Color( r, g, b, alpha );

		alpha = satellite_color.getAlpha();
		satellite_color = new Color( r, g, b, alpha );

	}

	public void copyColors( Tweet tweet ) {
		node_fill_color = tweet.node_fill_color;
		node_stroke_color = tweet.node_stroke_color;
		satellite_color = tweet.satellite_color;
	}

	public void setRoot(String _root) {
		tree_root_node = _root;
	}

	private void setupAnimations() {
		fade_out = new Tween(parent, newFadeOutTime, Tween.SECONDS);
		fade_out.setPlayMode(Tween.ONCE);

		BezierShaper bezier = new BezierShaper(Shaper.SIGMOID, 1);
		// TODO: play with these params!!!
		bezier.setInHandle( 0.9f, 0f );
		bezier.setOutHandle( 0.4f, -0.2f );
		bezier.clamp();
		fade_out.setEasing(bezier);
		//fade_out.setEasingMode(Shaper.IN);
		//fade_out.start();
	}


	public void setTreeRoot(String root) {
		tree_root_node = root;
	}

	public String getTreeRoot() {
		return tree_root_node;
	}

	public Vector3D position() {
		return particle.position();
	}

	public Vector3D velocity() {
		return particle.velocity();
	}

	/**
	 *
	 *
	 */
	public void draw() {

		if(last_position.distanceTo(particle.position()) > max_movement_allowed ) {
			particle.makeFixed();
			Twt.println("Node fixed");
		}

		// These transformations ensure that both text and node are always parallel to the screen
		parent.pushMatrix();
		parent.translate(position().x(), position().y(), position().z());
		parent.rotateX(-parent.angleX);
		parent.rotateY(-parent.angleY);

		if(show_text && !is_newcommer) drawText();
		if(show_node) drawNode();

		parent.popMatrix();

		if(global_alpha > 0.6) global_alpha *= decay_rate;

		last_position = new Vector3D(particle.position());
	}

	private void drawText() {
		float x_inc = 0;
		float y_inc = 0;
		parent.textFont(parent.tweet_font);
		parent.fill(text_color.getRGB(), fade_out_intensity / (float)hop_level);
		parent.textSize(parent.textSize * fade_out_intensity / (Tweet.max_fade_out_intensity * (float)Math.pow(hop_level, 0.3) ));
		parent.textAlign(Twt.LEFT);

		int word_count = 0;
		float n_instensity = fade_out_intensity / 255f;
		PVector dest;

		boolean is_username = true;
		parent.pushMatrix();
		parent.rotate(inclination);
		for (int i = 0; i < words.length; i++) {
			dest = new PVector(x_inc*n_instensity, y_inc*n_instensity);
			parent.pushMatrix();
			parent.translate(dest.x, dest.y);
			parent.rotate(word_angles[i]*(1-n_instensity));
			parent.text(words[i], 0, 0);
			parent.popMatrix();
			x_inc += parent.textWidth(words[i] + " ");
			word_count += words[i].length();
			if(word_count >= max_line_length | is_username) {
				is_username = false;
				word_count = 0;
				x_inc = 0;
				y_inc += parent.textAscent() + parent.textDescent();
			}
		}
		parent.popMatrix();

		//fade_out_intensity *= Tweet.tau;	// using tau as decay control
		fade_out_intensity = (int)(255*(1-fade_out.position()));	// using shapetween as animation control
		if(fade_out_intensity < 1) show_text = false;
	}

	private void drawNode() {
		parent.strokeWeight(1);
		parent.stroke(node_stroke_color.getRGB(), (float)node_stroke_color.getAlpha() * global_alpha);
		parent.fill(node_fill_color.getRGB(), (float)node_fill_color.getAlpha() * global_alpha);
		parent.ellipse(0, 0, ellipse_width, ellipse_height);
		drawSatellites();
	}

	private void drawSatellites() {
		parent.strokeWeight(1);
		parent.stroke(satellite_color.getRGB(), (float)(255 - fade_out_intensity) * global_alpha);
		parent.fill(satellite_color.getRGB(), (float)(255 - fade_out_intensity) * global_alpha);
		PVector x_hat = new PVector(orbit_radius, 0, 0);
		for(int i = 0; i < words.length; i++) {
			PVector from = Utils.rotate2D(x_hat, i*Twt.TWO_PI/words.length) ;
			parent.ellipse(from.x, from.y, 2f, 2f);

			if(show_leaves) {
				PVector to = Utils.rotate2D(x_hat, (i+1)*Twt.TWO_PI/words.length);
				PVector fuge = PVector.mult(PVector.add(from, to), 0.7f);
				parent.bezier(from.x, from.y, from.z,
						fuge.x, fuge.y, fuge.z,
						fuge.x, fuge.y, fuge.z,
						to.x, to.y, to.z);
			}
		}
	}

	/**
	 *
	 *
	 */

	public void highlight(int _hop_level) {

		if(is_new) fade_out.setDuration(newFadeOutTime, Tween.SECONDS);
		else fade_out.setDuration(triggerFadeOutTime, Tween.SECONDS);

		if(fade_out.isTweening())
			fade_out.end();

		this.hop_level = _hop_level;
		parent.noStroke();

		// place throb and colorize change here
		if (is_local) text_color = Colors.keywordTweetColor;
		else if (is_new) text_color = Colors.newTweetColor;
		else text_color = Colors.echoColor;

		// don't forget to set alpha to max and show_text to true
		fade_out_intensity = (int)Tweet.max_fade_out_intensity;
		show_text = true;
		global_alpha = 1.0f;

		// start the fade out animation
		fade_out.start();

		is_new = false;

	}

	public void addLink(Link _link) {
		links.add(_link);
	}

	public float age() {
		return parent.millis() - dob;
	}

}
