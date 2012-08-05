import java.awt.Color;

import megamu.shapetween.*;
import traer.physics.*;

public class Link {

	Tweet left;
	Tweet right;
	float strength;
	Twt parent;
	Spring spring;
	
	
	private Vector3D lru;
	private Vector3D rlu;
	private float min_angle;
	private float max_angle;
	private float left_angle;
	private float right_angle;
	private Tween left_ang_animation;
	private Tween right_ang_animation;
	private Color link_color;
	
	/**
	 * 
	 * 
	 * @param _left
	 * @param _right
	 * @param value
	 * @param _parent
	 * @param _spring
	 */
	public Link( Tweet _left, Tweet _right, float value, Twt _parent, Spring _spring) {
		left = _left;
		right = _right;
		strength = value;
		parent = _parent;
		spring = _spring;
		
		//link_color = Colors.link_color;
		link_color = left.node_fill_color;
		
		min_angle = parent.random(-1,0.1F)*Twt.PI/16;
		max_angle = parent.random(0.1F,1)*Twt.PI/16;
		left_angle = min_angle;
		right_angle = min_angle;
		
		left_ang_animation = new Tween(parent, parent.random(1.5F,3F), Tween.SECONDS); 
		right_ang_animation = new Tween(parent, parent.random(1.5F,3F), Tween.SECONDS);
		left_ang_animation.setPlayMode(Tween.REVERSE_REPEAT);
		right_ang_animation.setPlayMode(Tween.REVERSE_REPEAT);
		left_ang_animation.setEasing(Tween.COSINE);
		right_ang_animation.setEasing(Tween.COSINE);
		left_ang_animation.setEasingMode(Tween.IN_OUT);
		right_ang_animation.setEasingMode(Tween.IN_OUT);
		left_ang_animation.start();
		right_ang_animation.start();
		
		ComputeGeometry();
		
	}
	
	private void ComputeGeometry() {
		lru = new Vector3D(right.position());
		lru.subtract(left.position());
		
		lru = lru.multiplyBy(0.25f);
		rlu = new Vector3D(lru);
		rlu = rlu.multiplyBy(-1);
		
		left_angle = Twt.lerp(min_angle, max_angle, left_ang_animation.position());
		right_angle = Twt.lerp(min_angle, max_angle, right_ang_animation.position());
		
		// FIXME: rotation must be in 3D now!!!
		lru = Utils.rotate2D(lru, left_angle);
		rlu = Utils.rotate2D(rlu, right_angle);
	}
	
	public void draw() {

		ComputeGeometry();
		parent.noFill();
		parent.stroke(link_color.getRGB(), link_color.getAlpha());
		parent.strokeWeight(2);
		parent.bezier(left.position().x(), left.position().y(), left.position().z(), 
						left.position().x()+lru.x(), left.position().y()+lru.y(), left.position().z()+lru.z(),
						right.position().x()+rlu.x(), right.position().y()+rlu.y(), right.position().z()+rlu.z(),
						right.position().x(), right.position().y(), right.position().z());
		parent.noFill();
		
	}
	
}
