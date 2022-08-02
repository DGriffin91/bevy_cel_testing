#import bevy_pbr::mesh_view_bindings
#import bevy_pbr::mesh_bindings
#import bevy_pbr::pbr_types
#import bevy_pbr::utils
#import bevy_pbr::clustered_forward
#import bevy_pbr::lighting
#import bevy_pbr::shadows
#import bevy_pbr::pbr_functions

//struct CustomMaterial {
//    color: vec4<f32>,
//};
//@group(1) @binding(0)
//var<uniform> material: CustomMaterial;

fn rgb2hsv(c: vec3<f32>) -> vec3<f32> {
    let K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    let p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    let q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    let d = q.x - min(q.w, q.y);
    let e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

fn hsv2rgb2(c: vec3<f32>) -> vec3<f32> {
    let K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    let p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, vec3(0.0), vec3(1.0)), c.y);
}

fn posterize(inputColor: vec3<f32>, steps: f32) -> vec3<f32> {
  let gamma = 0.3;
  
  var c = inputColor;
  c = pow(c, vec3(gamma, gamma, gamma));
  c = c * steps;
  c = floor(c);
  c = c / steps;
  c = pow(c, vec3(1.0/gamma));
  
  return c;
}

// not working with gamma on posterize, bring values end up smoother
fn smoothfloor(x: f32, width: f32) -> f32 {
    return floor(x) + clamp( 1.-(1.-fract(x))/width, 0.,1.);
}

fn posterize1(inputColor: f32, steps: f32, gamma: f32) -> f32 {
  var c = inputColor;
  c = pow(c, gamma);
  c = c * steps;
  c = floor(c);
  c = c / steps;
  c = pow(c, 1.0/gamma);
  
  return c;
}

struct FragmentInput {
    @builtin(front_facing) is_front: bool,
    @builtin(position) frag_coord: vec4<f32>,
    #import bevy_pbr::mesh_vertex_output
};
@fragment
fn fragment(in: FragmentInput) -> @location(0) vec4<f32> {
    //Compute normals
    let normal = prepare_normal(
            0u,
            in.world_normal,
            #ifdef VERTEX_TANGENTS
                #ifdef STANDARDMATERIAL_NORMAL_MAP
                    in.world_tangent,
                #endif
            #endif
            #ifdef VERTEX_UVS
                in.uv,
            #endif
            in.is_front,
        );

    let uv = in.frag_coord.xy / vec2<f32>(view.width, view.height);

    var diffuse_color = vec4(1.0,1.0,1.0,1.0);//material.color;

#ifdef VERTEX_COLORS
    diffuse_color = diffuse_color * in.color;
#endif



    // accumulate color
    var light_accum: vec3<f32> = vec3<f32>(0.0);
    let view_z = dot(vec4<f32>(
        view.inverse_view[0].z,
        view.inverse_view[1].z,
        view.inverse_view[2].z,
        view.inverse_view[3].z
    ), in.world_position);
    let cluster_index = fragment_cluster_index(in.frag_coord.xy, view_z, false);
    let offset_and_counts = unpack_offset_and_counts(cluster_index);
    // directional lights
    let n_directional_lights = lights.n_directional_lights;
    for (var i: u32 = 0u; i < n_directional_lights; i = i + 1u) {
        let light = lights.directional_lights[i];
        var shadow: f32 = 1.0;
        if ((mesh.flags & MESH_FLAGS_SHADOW_RECEIVER_BIT) != 0u
                && (light.flags & DIRECTIONAL_LIGHT_FLAGS_SHADOWS_ENABLED_BIT) != 0u) {
            shadow = fetch_directional_shadow(i, in.world_position, in.world_normal);
        }
        let incident_light = light.direction_to_light.xyz;
        let NoL = saturate(dot(normal, incident_light)); // Lambert
        let light_contrib = diffuse_color.rgb * light.color.rgb * NoL;
        light_accum = light_accum + light_contrib * shadow;
    }
    var output_color = vec4<f32>(light_accum + diffuse_color.rgb * lights.ambient_color.rgb, 1.0);

    var c = tone_mapping(output_color);
    
    var hsv = rgb2hsv(output_color.rgb);

    hsv.x = posterize1(hsv.x, 20.0, 1.0);
    hsv.y = posterize1(hsv.y, 7.0, 1.0);
    hsv.z = posterize1(hsv.z, 4.0, 0.3);

    

    return vec4(hsv2rgb2(hsv), 1.0);
}