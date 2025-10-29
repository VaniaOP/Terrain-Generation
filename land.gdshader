shader_type canvas_item;

uniform vec2 offset = vec2(0, 0);

/* 150-160 works best imo*/
uniform float max_height = 1.0;

uniform int texture_type = 0;


vec3 mod289_3(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289_2(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289_3(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
    vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                  0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                 -0.577350269189626,  // -1.0 + 2.0 * C.x
                  0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    
    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = vec4(x0.xy, x0.xy) + C.xxzz;
    x12.xy -= i1;
    
    // Permutations
    i = mod289_2(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    	+ i.x + vec3(0.0, i1.x, 1.0 ));
    
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), vec3(0.0));
    m = m*m ;
    m = m*m ;
    
    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
    
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    
    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    
    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

vec3 encode_normal(vec3 n){
	return (0.5 * (n + vec3(1.0))).rbg;
}

vec4 linear_interpolate(vec4 a, vec4 b, float ammount){
	return a + (b - a) * ammount;
}

float get_height(float x, float y) {
	float base_noise = snoise((vec2(x, y) + offset) * 2.0) * 0.5 + 0.5;
	
	float dist = distance(vec2(x, y), vec2(0.5, 0.5));
	float inv_dist = 1.0 - dist / 0.5;
	
	float base = inv_dist / 0.25 * base_noise;
	
	float layer_noise = snoise((vec2(x, y) + offset) * 10.0) * 0.5;
	
	float result = base / 4.0 + layer_noise / 60.0;
	
	return result;
}

void fragment() {
	float height = get_height(UV.x, UV.y);
	float real_height = height * max_height;
	
	float h_right = max_height * get_height(UV.x + 0.0000244140625, UV.y);
	float h_forward = max_height * get_height(UV.x, UV.y + 0.0000244140625);
	vec3 normal = normalize(vec3(real_height - h_right, 0.1, h_forward - real_height));
	
	vec4 splat = vec4(1.0, 0.0, 0.0, 0.0);
	float slope = 4.0 * dot(normal, vec3(0.0, 1.0, 0.0)) - 2.0;
	float slope_amount = clamp(1.0 - slope, 0.0, 1.0);
	float sand_amount = clamp(30.0 - real_height, 0.0, 1.0);
	
	splat = linear_interpolate(splat, vec4(0.0,1.0,0.0,0.0), sand_amount);
	splat = linear_interpolate(splat, vec4(0.0,0.0,0.0,1.0), slope_amount);
	
	switch (texture_type){
		case 0:
			COLOR.rgb = vec3(real_height, 0.0, 0.0);
			break;
		case 1:
			COLOR.rgb = encode_normal(normal);
			break;
		case 2:
			COLOR.rgb = splat.rgb;
			break;
		case 3:
			COLOR.rgb = vec3(splat.a, 0, 0);
			break;
		
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
