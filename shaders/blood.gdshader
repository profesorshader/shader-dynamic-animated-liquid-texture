// https://www.youtube.com/@ProfesorShader
// https://github.com/profesorshader
shader_type texture_blit;
render_mode blend_mix;

uniform vec3 blood_color : source_color = vec3(0.8, 0.0, 0.0);
uniform vec3 background_color : source_color = vec3(0.0, 0.0, 0.0);

uniform float flow_velocity = 0.5;
uniform float velocity_keep = 0.998;
uniform sampler2D wet_map : hint_blit_source0;
uniform sampler2D height_map; // try with godot's default simple noise
uniform float height_mult = 20.0; // this value scales noise texture
uniform float mask_min = 0.0;
uniform float mask_max = 0.75;

uniform float texel_size = 0.002; // 1.0 / 512

void blit() {
	// compute UVs
	vec2 up_l = vec2(UV.x - texel_size, UV.y - texel_size);	
	vec2 up_c = vec2(UV.x, UV.y - texel_size);
	vec2 up_r = vec2(UV.x + texel_size, UV.y - texel_size);	
	vec2 down_l = vec2(UV.x - texel_size, UV.y + texel_size);
	vec2 down_c = vec2(UV.x, UV.y + texel_size);
	vec2 down_r = vec2(UV.x + texel_size, UV.y + texel_size);
	
	// read bloods
	vec2 blood_ul = texture(wet_map, up_l).rg;	
	vec2 blood_uc = texture(wet_map, up_c).rg;
	vec2 blood_ur = texture(wet_map, up_r).rg;	
	vec2 blood_c = texture(wet_map, UV).rg;
	//vec2 blood_dl = texture(wet_map, down_l).rg;
	//vec2 blood_dc = texture(wet_map, down_c).rg;
	//vec2 blood_dr = texture(wet_map, down_r).rg;
	
	// read heights
	float height_ul = texture(height_map, up_l).r * height_mult;
	float height_uc = texture(height_map, up_c).r * height_mult;
	float height_ur = texture(height_map, up_r).r * height_mult;			
	float height_c = texture(height_map, UV).r * height_mult;
	float height_dl = texture(height_map, down_l).r * height_mult;
	float height_dc = texture(height_map, down_c).r * height_mult;
	float height_dr = texture(height_map, down_r).r * height_mult;	
	
	// how many liquid and velocity was lost (down)
		
	// how many liquid was lost? splope = 0 -> max liquid lost
	float slope_dl = (1.0 - abs(height_dl - height_c)) * 0.25;
	float slope_dc = (1.0 - abs(height_dc - height_c)) * 0.5;
	float slope_dr = (1.0 - abs(height_dr - height_c)) * 0.25;
	float flow_lost = blood_c.r * (slope_dl + slope_dc + slope_dr ) * flow_velocity * blood_c.g;
	
	// how many velocity was lost? 
	float velocity_lost = blood_c.g * (slope_dl + slope_dc + slope_dr ) * flow_velocity;

	// how many liquid and velocity was gain (from above)
		
	// how many liquid was gain? splope = 0 -> max liquid gain
	float slope_ul = (1.0 - abs(height_ul - height_c)) * 0.25;
	float slope_uc = (1.0 - abs(height_uc - height_c)) * 0.5;
	float slope_ur = (1.0 - abs(height_ur - height_c)) * 0.25;
	float flow_gain = 
		blood_ul.r * slope_ul * flow_velocity * blood_ul.g +
		blood_uc.r * slope_uc * flow_velocity * blood_uc.g +
		blood_ur.r * slope_ur * flow_velocity * blood_ur.g ;

	// how many velocity was gain? 
	float velocity_gain = 
		blood_ul.g * slope_ul * flow_velocity +
		blood_uc.g * slope_uc * flow_velocity +
		blood_ur.g * slope_ur * flow_velocity;

	// compute final liquid amount
	float final_flow = min(1.0, max(0.0, blood_c.x - flow_lost) + flow_gain);
	
	// compute final velocity 
	float final_velocity = min(1.0, max(0.0, blood_c.y - velocity_lost) + velocity_gain) * velocity_keep;
		
	// write to wet_map B
	COLOR1 = vec4(final_flow, final_velocity, 0.0, 1.0);	

	// generate color/albedo map from wet map
	float mask = smoothstep(mask_min, mask_max, COLOR1.x);
	vec3 albedo_color = mix(background_color, blood_color, mask);		
	COLOR0 = vec4(albedo_color, 1.0);	
}
