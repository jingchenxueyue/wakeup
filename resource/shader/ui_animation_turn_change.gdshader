shader_type canvas_item;

// 动画时间控制
uniform float reveal_duration = 0.5;	// 图像显示所需时间
uniform float hold_duration = 1.0;	// 图像持续显示的时间
uniform float hide_duration = 0.5;	// 图像消失所需时间

uniform float time = -100.0;			// 动画经过的时间，需要每帧从外部设置

float ease_out_expo(float x) {
	return 1.0 - pow(2.0, -10.0 * x);
}

float linear(float x) {
	return clamp(x, 0.0, 1.0);
}

void fragment() {

	// 获取当前时间

	float alpha = 0.0;
	vec3 final = vec3(0.6);

	if (time <= reveal_duration){

		float progress = time / reveal_duration;
		alpha = step(UV.x, ease_out_expo(progress));
	}
	else if (time <= reveal_duration + hold_duration) {
		alpha = 1.0;
	}
	else {

		float tmp_time = time - reveal_duration - hold_duration;

		alpha = step(linear( tmp_time / hide_duration), 1.0 - UV.x);
	}

	// 将 alpha 值应用到最终颜色
	COLOR = vec4(final, alpha);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
