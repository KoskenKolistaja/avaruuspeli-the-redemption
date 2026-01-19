shader_type spatial;
render_mode ambient_light_disabled;

// --- INPUTS ---
group_uniforms Textures;
uniform sampler2D earth_mask : source_color, filter_linear_mipmap;

group_uniforms Colors;
uniform vec3 deep_ocean_color : source_color = vec3(0.0, 0.4, 0.6);
uniform vec3 beach_color : source_color = vec3(0.25, 0.87, 0.81);
uniform vec3 land_color : source_color = vec3(0.46, 0.86, 0.46);
uniform vec3 shadow_color : source_color = vec3(0.0, 0.0, 0.2);

group_uniforms Map_Settings;
// How bright the pixel must be to become beach
uniform float beach_threshold : hint_range(0.0, 1.0) = 0.1; 
// How bright the pixel must be to become land
uniform float land_threshold : hint_range(0.0, 1.0) = 0.3;  
// Smoothness of the transition between land/sea (anti-aliasing)
uniform float transition_smoothness : hint_range(0.001, 0.1) = 0.01;

group_uniforms Plastic_Look;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float specular_size : hint_range(0.0, 1.0) = 0.05;
uniform float rim_amount : hint_range(0.0, 1.0) = 0.2;
uniform float shadow_sharpness : hint_range(0.0, 1.0) = 0.01;

void fragment() {
	// 1. Read the Black & White Mask
	float mask_value = texture(earth_mask, UV).r;

	// 2. Calculate Colors based on Mask Value (The "Beach Calculator")
	vec3 final_albedo = deep_ocean_color;
	
	// Mix Ocean -> Beach
	float is_beach = smoothstep(beach_threshold, beach_threshold + transition_smoothness, mask_value);
	final_albedo = mix(final_albedo, beach_color, is_beach);
	
	// Mix Beach -> Land
	float is_land = smoothstep(land_threshold, land_threshold + transition_smoothness, mask_value);
	final_albedo = mix(final_albedo, land_color, is_land);

	// 3. Output to PBR
	ALBEDO = final_albedo;
	ROUGHNESS = roughness;
	SPECULAR = 0.0; // We handle specular manually in light() for the cartoon look
}

void light() {
	// --- TOON DIFFUSE (Shadows) ---
	// Calculate basic light intensity (N dot L)
	float NdotL = dot(NORMAL, LIGHT);
	
	// Create the sharp "Toon" cut
	// smoothstep creates a sharp transition instead of a gradient
	float light_intensity = smoothstep(0.0, shadow_sharpness, NdotL);
	
	// Determine light color (Lit vs Shadow)
	vec3 light_color = mix(shadow_color * ALBEDO, LIGHT_COLOR * ALBEDO, light_intensity);
	
	// --- TOON SPECULAR (The Plastic Shine) ---
	// Calculate the reflection vector
	vec3 half_vector = normalize(VIEW + LIGHT);
	float NdotH = max(0.0, dot(NORMAL, half_vector));
	
	// Create a super sharp, tiny dot for the plastic look
	float specular_intensity = pow(NdotH, 1.0 / (specular_size * specular_size));
	specular_intensity = smoothstep(0.5, 0.51, specular_intensity); // Hard cut
	
	// --- RIM LIGHT (Cute edge glow) ---
	float rim_dot = 1.0 - dot(VIEW, NORMAL);
	float rim = smoothstep(0.6, 1.0, rim_dot) * rim_amount * light_intensity;
	
	// --- FINAL COMBINATION ---
	// Diffuse + Specular + Rim
	DIFFUSE_LIGHT += (light_color * ATTENUATION) + (vec3(specular_intensity) * LIGHT_COLOR) + (rim * LIGHT_COLOR);
}
