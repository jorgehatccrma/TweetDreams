import java.awt.Color;
import java.util.Vector;

import megamu.shapetween.BezierShaper;
import megamu.shapetween.Shaper;
import megamu.shapetween.Tween;


public class IncomingStack {
	
	public static float display_time = 2000f;  // in milliseconds
	private static float fade_out_time = 100f;   // in milliseconds
	private static float fade_in_time = 1000f;   // in milliseconds
	
	private Twt parent;
	private static float separation_factor = 1.5f;
	
	private Vector<Tweet> new_tweets_stack = new Vector<Tweet>();
	private Vector<Tween> fade_outs = new Vector<Tween>();
	private Vector<Tween> fade_ins = new Vector<Tween>();
	
	private Color color;
	
	// TODO: make the position of the stack a parameter (TL, TR, BL or BR, for example),
	// so is possible to display different stacks showing local or global tweets
	public IncomingStack( Twt parent, Color color ) {
		this.parent = parent;
		this.color = color;
	}
	
	public void addTweet( Tweet tweet ) {
		new_tweets_stack.add(tweet);
	}
	
	
	private Tween setUpFadeout() {
		Tween fade_out = new Tween(parent, IncomingStack.fade_out_time/1000f, Tween.SECONDS);
		fade_out.setPlayMode(Tween.ONCE);
		
		BezierShaper bezier = new BezierShaper(Shaper.SIGMOID, 1);
		bezier.setInHandle( 0.9f, 0f );
		bezier.setOutHandle( 0f, 0.2f );
		bezier.clamp();
		fade_out.setEasing(bezier);
		return fade_out;
	}
	
	private Tween setUpFadein() {
		Tween fade_in = new Tween(parent, IncomingStack.fade_in_time/1000f, Tween.SECONDS);
		fade_in.setPlayMode(Tween.ONCE);
		
		BezierShaper bezier = new BezierShaper(Shaper.SIGMOID, 1);
		bezier.setInHandle( 0.1f, 0.1f );
		bezier.setOutHandle( -2.5f, 1.0f );
		bezier.clamp();
		fade_in.setEasing(bezier);
		return fade_in;
	}

	public void draw(float rect_width, float rect_height, float right_edge, float bottom_edge) {
		
		//parent.println(".");
		
		parent.textFont(parent.stack_font);
		parent.textSize(parent.new_tweets_stack_font_size);
		parent.textAlign(Twt.RIGHT);
		float z_pos = 0;
		float line_height = parent.textAscent() + parent.textDescent();
		float top_edge = bottom_edge - rect_height;
		float current_y = bottom_edge - rect_height;//bottom_edge - parent.textDescent();
		float cum_fade_out_correction = 0f;
		
		int fades_to_remove = 0;
		
		synchronized (new_tweets_stack) {
			for (int i = 0; i < new_tweets_stack.size(); i++) {
				//parent.println(i);
				float target_y = bottom_edge - parent.textDescent() - (float)i*(line_height*separation_factor);
				Tweet tweet = new_tweets_stack.elementAt(i);
				if ( tweet.age() < IncomingStack.fade_in_time ) {
					if( fade_ins.size() <= i) fade_ins.add(setUpFadein());
					parent.fill( color.getRGB(), 127*fade_ins.elementAt(i).position());
					current_y = top_edge + (target_y - top_edge) * fade_ins.elementAt(i).position();
					//parent.println("fading in at " + current_y);
				} else if( tweet.age() > IncomingStack.display_time + IncomingStack.fade_in_time ) {
					if( fade_outs.size() <= i) fade_outs.add(setUpFadeout());
					parent.fill( color.getRGB(), 127*(1f - fade_outs.elementAt(i).position()));
					current_y = target_y + line_height*separation_factor*fade_outs.elementAt(i).position();
					cum_fade_out_correction += line_height*separation_factor*fade_outs.elementAt(i).position();
					//parent.println("fading out at " + current_y);
					if( !fade_outs.elementAt(i).isTweening() ) {
						fades_to_remove += 1;
						tweet.is_newcommer = false;
					}
				} else {
					parent.fill( color.getRGB(), color.getAlpha());
					//parent.println("showing at " + current_y);
					current_y = target_y;
				}
				// FIXME: there's a blink after a tweet is removed from the stack. Why? 
				parent.text(tweet.the_tweet, right_edge, current_y + cum_fade_out_correction, z_pos);
			}
			
			while (fades_to_remove > 0) {
				fade_outs.removeElementAt( 0 );
				fade_ins.removeElementAt( 0 );
				new_tweets_stack.removeElementAt( 0 );
				fades_to_remove--;
			}

		}
		
	}

	
}
