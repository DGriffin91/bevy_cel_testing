//! A simple 3D scene with light shining over a cube sitting on a plane.

use bevy::{
    asset::AssetServerSettings,
    pbr::NotShadowCaster,
    prelude::*,
    reflect::TypeUuid,
    render::render_resource::{AsBindGroup, ShaderRef},
};

use bevy_basic_camera::{CameraController, CameraControllerPlugin};

fn main() {
    App::new()
        .insert_resource(AssetServerSettings {
            watch_for_changes: true,
            ..default()
        })
        .add_plugins(DefaultPlugins)
        .add_startup_system(setup)
        .add_plugin(MaterialPlugin::<SkyMaterial>::default())
        .add_plugin(MaterialPlugin::<BuildingsMaterial>::default())
        .add_plugin(MaterialPlugin::<StreetMaterial>::default())
        .add_plugin(MaterialPlugin::<CelMaterial>::default())
        .add_plugin(CameraControllerPlugin)
        .run();
}

/// set up a simple 3D scene
fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut sky_materials: ResMut<Assets<SkyMaterial>>,
    mut buildings_materials: ResMut<Assets<BuildingsMaterial>>,
    mut street_materials: ResMut<Assets<StreetMaterial>>,
    mut cel_materials: ResMut<Assets<CelMaterial>>,
    ass: Res<AssetServer>,
) {
    // directional 'sun' light
    const HALF_SIZE: f32 = 200.0;
    commands.spawn_bundle(DirectionalLightBundle {
        directional_light: DirectionalLight {
            // Configure the projection to better fit the scene
            shadow_projection: OrthographicProjection {
                left: -HALF_SIZE,
                right: HALF_SIZE,
                bottom: -HALF_SIZE,
                top: HALF_SIZE,
                near: -10.0 * HALF_SIZE,
                far: 10.0 * HALF_SIZE,
                ..default()
            },
            illuminance: 10000.0,
            shadows_enabled: true,
            ..default()
        },
        transform: Transform {
            translation: Vec3::new(0.0, 2.0, 0.0),
            rotation: Quat::from_euler(
                EulerRot::XYZ,
                (-70.0f32).to_radians(),
                (70.0f32).to_radians(),
                0.0,
            ),
            ..default()
        },
        ..default()
    });

    //Street
    commands.spawn().insert_bundle(MaterialMeshBundle {
        mesh: ass.load("models/city.glb#Mesh0/Primitive0"),
        material: street_materials.add(StreetMaterial {}),
        ..Default::default()
    });

    // Sidewalk
    commands.spawn().insert_bundle(MaterialMeshBundle {
        mesh: ass.load("models/city.glb#Mesh1/Primitive0"),
        material: buildings_materials.add(BuildingsMaterial {}),
        ..Default::default()
    });

    // Buildings
    commands
        .spawn()
        .insert_bundle(MaterialMeshBundle {
            mesh: ass.load("models/city.glb#Mesh2/Primitive0"),
            material: buildings_materials.add(BuildingsMaterial {}),
            ..Default::default()
        })
        .insert(NotShadowCaster);

    // Parking Meters
    commands.spawn().insert_bundle(MaterialMeshBundle {
        mesh: ass.load("models/city.glb#Mesh3/Primitive0"),
        material: buildings_materials.add(BuildingsMaterial {}),
        ..Default::default()
    });

    // Sky
    commands.spawn().insert_bundle(MaterialMeshBundle {
        mesh: ass.load("models/city.glb#Mesh4/Primitive0"),
        material: sky_materials.add(SkyMaterial {}),
        ..Default::default()
    });

    // Shaded
    commands.spawn().insert_bundle(MaterialMeshBundle {
        mesh: ass.load("models/city.glb#Mesh5/Primitive0"),
        material: cel_materials.add(CelMaterial {}),
        ..Default::default()
    });

    // Camera
    commands
        .spawn_bundle(Camera3dBundle {
            transform: Transform::from_xyz(-2.0, 2.5, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
            ..default()
        })
        .insert(CameraController::default());
}

#[derive(AsBindGroup, Debug, Clone, TypeUuid)]
#[uuid = "717f64fe-6844-4822-8926-e0ed374294c7"]
pub struct SkyMaterial {}
impl Material for SkyMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/sky.wgsl".into()
    }
}

#[derive(AsBindGroup, Debug, Clone, TypeUuid)]
#[uuid = "717f64fe-6844-4822-8926-e0ed374294c8"]
pub struct StreetMaterial {}
impl Material for StreetMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/street.wgsl".into()
    }
}

#[derive(AsBindGroup, Debug, Clone, TypeUuid)]
#[uuid = "717f64fe-6844-4822-8926-e0ed374294c9"]
pub struct BuildingsMaterial {}
impl Material for BuildingsMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/buildings.wgsl".into()
    }
}

#[derive(AsBindGroup, Debug, Clone, TypeUuid)]
#[uuid = "717f64fe-6844-4822-8926-e0ed374294ca"]
pub struct CelMaterial {}
impl Material for CelMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/cel.wgsl".into()
    }
}
