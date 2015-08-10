/*
	*	----------------------------
	*	Geometry shader: Bounce rays
	*	----------------------------
	* - Reflect, refract and scatter rays.
	* - Write out new rays to buffer.
	*/

layout(points) in;
layout(points) out;
in vec4 intersection[5]; // pos/size, ray/scatter, color/a, pixel/IOR/IOR, normal
out vec4 ray[4]; // pos/size, dir/scatter, color/a, pixel/IOR/0
uniform float max_samples; // 2^(2)^2

//
// A kind of inverse cross product. Assumes both parameters are normalised.
vec3 cross_bend( vec3 hand, vec3 pivot ) {
	vec3 span = cross( pivot, hand );
	float w   = length(span);
	return sqrt( 1.0 - w*w ) * hand + span;
}

//
// Scattering function, reused for reflection and refraction.
void scatter( vec3 r, float samples, float a, bool is_reflection ) {
	if( samples > 1.0 ) {
		// Make sure scattered rays will stay on the correct side of surface.
		vec3 r_cross                   = cross(normal, r);
		vec3 r_span                    = length(r_cross);
		if( r_span + scatter > 1.0 ) r = cross_bend( normal, (1.0 - scatter) * normalize(r_cross) );
		// Iterate through samples.
		float start = -(samples-1.0)/samples;
		float increment = 2.0/samples;
		float average_scatter = scatter/(samples*samples);
		a *= 1.0/(samples*samples);
		vec3 unit_x = normalize( cross(r, intersection) ); // Intersection is just any vector. Fails when dead-on…
		vec3 unit_y = cross(r, unit_x);
		for(float i=start; i<1.0; i+=increment) {
		for(float j=start; j<1.0; j+=increment) {
			vec2 offset = vec2(i, j);
			if( length(offset) > 1.0 ) offset /= length(offset);
			vec3 pivot = offset.x*unit_x + offset.y*unit_y; // Need to randomise?
			emit( cross_bend( r, pivot ), a, average_samples, is_reflection );
	}}} else {
		// No scatter
		emit( r, a, average_samples, is_reflection );
}}

//
// Emit rays into buffer.
void emit( vec3 r, float a, float average_scatter, bool is_reflection ) {
	ray[pos]     = intersection[pos];
	ray[dir]     = r;
	ray[color]   = intersection[color];
	ray[pixa]    = vec3( intersection[pixa].xy, intersextion[pixa].z * a );
	ray[scatIOR] = vec3(
		average_scatter,
		is_reflection? ray[scatIOR].y : ray[scatIOR].z,
		/* */ );
	EmitVertex();
}

void main() {
	// Calculate samples based on scatter.
	float samples = (scatter > 0.0 && max_samples > 0.0)?
			pow( 2.0, ceil( clamp(max_samples - log(scatter)/log(0.25), 0.0, max_samples) ) ) // Better to hard-code?
		:	1.0;
	float reflection = 1.0;
	float refraction = 0.0;
	// Refract
	if( IOR_to > 0.0 ) {
		reflection = abs(IOR_from - IOR_to) / (IOR_from + IOR_to);
		refraction = 1.0 - reflection;
		scatter( refract(ray, normal, IOR_from/IOR_to), samples, refraction, false );
	}
	// Reflect
	scatter( reflect(ray, normal), samples, reflection, true );
	EndPrimitive();
}
