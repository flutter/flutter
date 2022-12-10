## ⚠️ **Experimental:** Do not use in production! ⚠️

# Impeller Scene

Impeller Scene is an experimental realtime 3D renderer powered by Impeller's
render layer with the following design priorities:

* Ease of use.
* Suitability for mobile.
* Common case scalability.

The aim is to create a familiar and flexible scene graph capable of building
complex dynamic scenes for games and beyond.

## Example

```cpp
std::shared_ptr<impeller::Context> context =
    /* Create the backend-specific Impeller context */;

auto allocator = context->GetResourceAllocator();

/// Load resources.

auto dash_gltf = impeller::scene::LoadGLTF(allocator, "models/dash.glb");
auto environment_hdri =
    impeller::scene::LoadHDRI(allocator, "environment/table_mountain.hdr");

/// Construct a scene.

auto scene = impeller::scene::Scene(context);

scene.Add(dash_gltf.scene);

auto& dash_player = dash_gltf.scene.CreateAnimationPlayer();
auto& walk_action = dash_player.CreateClipAction(dash_gltf.GetClip("Walk"));
walk_action.SetLoop(impeller::scene::AnimationAction::kLoopForever);
walk_action.SetWeight(0.7f);
walk_action.Seek(0.0f);
walk_action.Play();
auto& run_action = dash_player.CreateClipAction(dash_gltf.GetClip("Run"));
run_action.SetLoop(impeller::scene::AnimationAction::kLoopForever);
run_action.SetWeight(0.3f);
run_action.Play();

scene.GetRoot().AddChild(
    impeller::scene::DirectionalLight(
        /* color */ impeller::Color::AntiqueWhite(),
        /* intensity */ 5,
        /* direction */ {2, 3, 4}));

Node sphere_node;
Mesh sphere_mesh;
sphere_node.SetGlobalTransform(
    Matrix::MakeRotationEuler({kPiOver4, kPiOver4, 0}));

auto sphere_geometry =
    impeller::scene::Geometry::MakeSphere(allocator, /* radius */ 2);

auto material = impeller::scene::Material::MakeStandard();
material->SetAlbedo(impeller::Color::Red());
material->SetRoughness(0.4);
material->SetMetallic(0.2);
// Common properties shared by all materials.
material->SetEnvironmentMap(environment_hdri);
material->SetFlatShaded(true);
material->SetBlendConfig({
  impeller::BlendOperation::kAdd,               // color_op
  impeller::BlendFactor::kOne,                  // source_color_factor
  impeller::BlendFactor::kOneMinusSourceAlpha,  // destination_color_factor
  impeller::BlendOperation::kAdd,               // alpha_op
  impeller::BlendFactor::kOne,                  // source_alpha_factor
  impeller::BlendFactor::kOneMinusSourceAlpha,  // destination_alpha_factor
});
material->SetStencilConfig({
  impeller::StencilOperation::kIncrementClamp,  // operation
  impeller::CompareFunction::kAlways,           // compare
});
sphere_mesh.AddPrimitive({sphere_geometry, material});
sphere_node.SetMesh(sphere_mesh);

Node cube_node;
cube_node.SetLocalTransform(Matrix::MakeTranslation({4, 0, 0}));
Mesh cube_mesh;
auto cube_geometry = impeller::scene::Geometry::MakeCuboid(
    allocator, {4, 4, 4});
cube_mesh.AddPrimitive({cube_geometry, material});
cube_node.SetMesh(cube_mesh);

sphere_node.AddChild(cube_node);
scene.GetRoot().AddChild(sphere_node);

/// Post processing.

auto dof = impeller::scene::PostProcessingEffect::MakeBokeh(
    /* aperture_size */ 0.2,
    /* focus_plane_distance */ 50);
scene.SetPostProcessing({dof});

/// Render the scene.

auto renderer = impeller::Renderer(context);

while(true) {
  std::unique_ptr<impeller::Surface> surface = /* Wrap the window surface */;

  renderer->Render(surface, [&scene](RenderTarget& render_target) {
    /// Render a perspective view.

    auto camera =
        impeller::Camera::MakePerspective(
            /* fov */ kPiOver4,
            /* position */ {50, -30, 50})
        .LookAt(
            /* target */ impeller::Vector3::Zero,
            /* up */ {0, -1, 0});

    scene.Render(render_target, camera);

    /// Render an overhead view on the bottom right corner of the screen.

    auto size = render_target.GetRenderTargetSize();
    auto minimap_camera =
        impeller::Camera::MakeOrthographic(
            /* view */ Rect::MakeLTRB(-100, -100, 100, 100),
            /* position */ {0, -50, 0})
        .LookAt(
            /* target */ impeller::Vector3::Zero,
            /* up */ {0, 0, 1})
        .WithViewport(IRect::MakeXYWH(size.width / 4, size.height / 4,
                                      size.height / 5, size.height / 5));

    scene.Render(render_target, minimap_camera);

    return true;
  });
}
```
