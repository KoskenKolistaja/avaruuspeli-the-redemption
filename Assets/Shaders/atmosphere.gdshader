shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded;

// --- SETTINGS ---
group_uniforms Atmosphere;
uniform vec4 atmosphere_color : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform float atmosphere_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float fresnel_power : hint_range(0.0, 10.0) = 4.0;

group_uniforms Cloud_Shapes;
uniform sampler2D cloud_mask_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D cloud_detail_texture : filter_linear_mipmap, repeat_enable;
uniform float cloud_density : hint_range(0.0, 2.0) = 0.8;
uniform float cloud_cutoff : hint_range(0.0, 1.0) = 0.4;

group_uniforms Cloud_Volumetrics;
uniform float bump_strength : hint_range(-2.0, 2.0) = 0.5; // Negative values invert the bump
uniform vec4 cloud_shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

group_uniforms Cloud_Movement;
uniform vec2 speed_mask = vec2(0.002, 0.0);
uniform vec2 speed_detail = vec2(0.006, 0.0);

// --- LIGHTING INPUT ---
// We use a GLOBAL direction so the light doesn't stick to the camera rotation
uniform vec3 light_direction_global = vec3(1.0, 0.0, 0.0);

// Helper to get cloud height at a specific position
float get_cloud_height(vec2 uv) {
    vec2 uv_mask = uv + (TIME * speed_mask);
    vec2 uv_detail = uv + (TIME * speed_detail);
    float mask = texture(cloud_mask_texture, uv_mask).r;
    float detail = texture(cloud_detail_texture, uv_detail).r;
    float combined = mask * detail;
    return smoothstep(cloud_cutoff, cloud_cutoff + 0.1, combined);
}

void fragment() {
    // 1. CONVERT SPACE: Global -> View
    // This transforms the light direction to match the camera's current angle
    vec3 light_dir_view = (VIEW_MATRIX * vec4(light_direction_global, 0.0)).xyz;

    // 2. Base Lighting (Day/Night)
    // We use the converted 'light_dir_view' here
    float sun_exposure = clamp(dot(NORMAL, light_dir_view), 0.0, 1.0);

    // 3. Atmosphere
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
    vec3 atm_color = atmosphere_color.rgb * atmosphere_intensity * fresnel;

    // 4. Volumetric Cloud Calculation
    float h_center = get_cloud_height(UV);
    float h_right  = get_cloud_height(UV + vec2(0.005, 0.0));
    float h_down   = get_cloud_height(UV + vec2(0.0, 0.005));

    // Calculate slopes
    float delta_x = h_center - h_right;
    float delta_y = h_center - h_down;
    
    // Create Bump Normal
    vec3 cloud_normal_offset = vec3(delta_x, delta_y, 0.0) * bump_strength;
    vec3 cloud_normal = normalize(NORMAL + cloud_normal_offset);

    // 5. Cloud Lighting
    // Check how much the BUMPED cloud faces the light (using the view-space light)
    float cloud_lit_amount = clamp(dot(cloud_normal, light_dir_view), 0.0, 1.0);
    
    // Mix bright white tops and dark shadow bottoms
    vec3 cloud_rgb = mix(cloud_shadow_color.rgb, vec3(1.0), cloud_lit_amount);
    
    // 6. Final Combine
    vec3 final_cloud = cloud_rgb * h_center * cloud_density;
    
    // Apply Atmosphere + Clouds, then mask by global sun exposure
    vec3 final_rgb = (atm_color + final_cloud) * sun_exposure;
    
    ALBEDO = final_rgb;
    ALPHA = clamp((fresnel + h_center) * sun_exposure, 0.0, 1.0);
}



