#import bevy_pbr::mesh_view_bindings
#import bevy_pbr::mesh_bindings

#import bevy_pbr::pbr_types
#import bevy_pbr::utils
#import bevy_pbr::clustered_forward
#import bevy_pbr::lighting
#import bevy_pbr::shadows
#import bevy_pbr::pbr_functions

struct FragmentInput {
    @builtin(front_facing) is_front: bool,
    @builtin(position) frag_coord: vec4<f32>,
    #import bevy_pbr::mesh_vertex_output
};

@fragment
fn fragment(in: FragmentInput) -> @location(0) vec4<f32> {
    let uv = in.frag_coord.xy / vec2<f32>(view.width, view.height);

    let grad = pow(uv.y * 3.0, 3.0);

    let col1 = vec4(0.0,0.0,0.01, 1.0);
    let col2 = vec4(0.01,0.03,0.1, 1.0);

    var diffuse_color = mix(col1, col2, grad);

    return tone_mapping(diffuse_color);
}