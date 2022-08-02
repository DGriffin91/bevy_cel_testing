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

    let grad = pow(uv.y * 1.5, 4.0);

    let col1 = vec4(0.01,0.03,0.2, 1.0) * 0.3; //material.color;
    let col2 = vec4(0.5,0.5,0.5, 1.0); //material.color;

    var diffuse_color = mix(col1, col2, grad);




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
        let NoL = max(0.0,abs(normal.x)) + max(0.0,max(-normal.z, 0.0)) + max(0.0,max(normal.y, 0.0)); // Lambert
        let light_contrib = diffuse_color.rgb * light.color.rgb * NoL;
        light_accum = light_accum + light_contrib * ceil(shadow);
    }
    var output_color = vec4<f32>(light_accum, 1.0); // + diffuse_color.rgb * lights.ambient_color.rgb
    
    // up light
    let grad = pow(uv.y * 2.0, 5.0);
    let col1 = vec4(0.01,0.03,0.1, 1.0) * 0.5;
    let col2 = vec4(0.2,0.2,0.2, 1.0); 
    output_color = mix(output_color, mix(col1, col2, grad), max(0.0,-normal.y) * 10.0);

    return tone_mapping(output_color);
}