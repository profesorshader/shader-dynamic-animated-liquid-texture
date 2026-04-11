// https://www.youtube.com/@ProfesorShader
// https://github.com/profesorshader
shader_type texture_blit;
render_mode blend_mix; 

uniform sampler2D splat_tex : hint_blit_source0;

void blit() {
	// read from texture
	float wet_amount = texture(splat_tex, UV).a;	
	// write to wet_map 
	COLOR0 = vec4(
		wet_amount,  // liquid amount
		wet_amount,  // liquid speed
		0.0, 
		wet_amount);
}
