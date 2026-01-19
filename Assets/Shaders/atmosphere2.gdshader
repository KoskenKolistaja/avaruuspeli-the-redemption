shader_type spatial;
// We use 'diffuse_toon' for a head start, but we will override light() for full control
render_mode specular_disabled; 

// --- Settings ---
group_uniforms Shape;
uniform float height_scale : hint_range(0.0, 2.0) = 0.5;
uniform float displacement_speed = 0.2;
uniform sampler3D noise_texture : repeat_enable; // The noise shape

group_uniforms Color;
uniform vec3 base_color : source_color = vec3(1.0, 1.0, 1.0); // White
uniform vec3 shadow_color : source_color = vec3(0.7, 0.75, 0.85); // Blue-Grey
uniform float rim_strength : hint_range(0.0, 10.0) = 3.0;
uniform float rim_width : hint_range(0.0, 1.0) = 0.3;

// --- Helper to get displacement at a specific position ---
float get_disp(vec3 pos, float time) {
	// Move the sample position over time to animate
	vec3 sample_pos = pos + (vec3(0.0, 1.0, 0.0) * time * displacement_speed);
	
	// Sample the texture. We use textureLod to read it in the Vertex shader.
	// We use the red channel (r) of the noise.
	float noise = textureLod(noise_texture, sample_pos * 0.5, 0.0).r;
	
	// Remap noise from 0..1 to -1..1 if you want indentations too, 
	// but for clouds, 0..1 (puffing out only) often looks fluffier.
	return noise * height_scale;
}

void vertex() {
	// 1. DISPLACEMENT
	float d = get_disp(VERTEX, TIME);
	
	// 2. NORMAL RECALCULATION
	// Since we are moving vertices, the old normals are wrong (they are smooth).
	// We must calculate the "slope" of the new noise shape to get crisp shadows.
	
	float e = 0.01; // Epsilon (tiny offset)
	
	// Create two neighbor points (tangent and bitangent)
	vec3 tangent = normalize(cross(NORMAL, vec3(0.0, 1.0, 0.0)));
	if (length(tangent) < 0.001) { // Handle poles where cross product might fail
		tangent = normalize(cross(NORMAL, vec3(0.0, 0.0, 1.0)));
	}
	vec3 bitangent = normalize(cross(NORMAL, tangent));
	
	// Calculate positions of neighbors
	vec3 p_center = VERTEX;
	vec3 p_right  = VERTEX + tangent * e;
	vec3 p_up     = VERTEX + bitangent * e;
	
	// Apply displacement to neighbors
	p_center += NORMAL * d;
	p_right  += NORMAL * get_disp(p_right, TIME);
	p_up     += NORMAL * get_disp(p_up, TIME);
	
	// Calculate new normal based on the triangle formed by these points
	vec3 new_normal = normalize(cross(p_up - p_center, p_right - p_center));
	
	// Apply changes
	VERTEX = p_center;
	NORMAL = new_normal;
}

void fragment() {
	// Just pass the color to the light processor
	ALBEDO = base_color;
	ROUGHNESS = 1.0; // Clouds are not shiny
}

void light() {
	// --- CARTOON LIGHTING ---
	
	// 1. Calculate how much light hits the surface (0.0 to 1.0)
	float NdotL = dot(NORMAL, LIGHT);
	
	// 2. Snap the light (Cel Shading)
	// Instead of a gradient, we make a hard cut between light and shadow.
	// smoothstep(-0.05, 0.05) makes a slightly soft edge (Ghibli style) 
	// rather than a pixel-perfect hard edge.
	float light_intensity = smoothstep(-0.05, 0.05, NdotL);
	
	// 3. Rim Light (The glowing edge)
	// VIEW is the vector from camera to pixel.
	float view_dot = 1.0 - dot(VIEW, NORMAL);
	float rim = smoothstep(1.0 - rim_width, 1.0, view_dot) * light_intensity * rim_strength;
	
	// 4. Combine
	vec3 lighting = mix(shadow_color, base_color * ATTENUATION, light_intensity);
	
	// Add Rim (clamped so it doesn't blow out)
	lighting += vec3(rim);
	
	// Output final light
	DIFFUSE_LIGHT += lighting * ALBEDO * LIGHT_COLOR;
}




