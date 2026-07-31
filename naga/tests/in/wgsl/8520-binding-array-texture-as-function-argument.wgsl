// Regression test for #8520: handles pulled out of a `binding_array` and passed
// to a user function used to be passed by value, while the callee's parameter is
// a pointer, producing SPIR-V that failed validation.
enable wgpu_binding_array;

struct UniformIndex {
    index: u32,
}

@group(0) @binding(0)
var texture_array: binding_array<texture_2d<f32>, 5>;
@group(0) @binding(1)
var sampler_array: binding_array<sampler, 5>;
@group(0) @binding(2)
var single_texture: texture_2d<f32>;
@group(0) @binding(3)
var<uniform> uni: UniformIndex;

fn sample_texture(texture: texture_2d<f32>, samp: sampler, uv: vec2<f32>) -> vec4<f32> {
    return textureSampleLevel(texture, samp, uv, 0.0);
}

fn load_texture(texture: texture_2d<f32>) -> vec4<f32> {
    return textureLoad(texture, vec2<i32>(0, 0), 0);
}

@fragment
fn main() -> @location(0) vec4<f32> {
    let uv = vec2<f32>(0.5, 0.5);
    let uniform_index = uni.index;

    var result = vec4<f32>(0.0);

    // constant index, `AccessIndex` in the IR
    result += sample_texture(texture_array[0], sampler_array[0], uv);
    result += load_texture(texture_array[1]);

    // dynamic index, `Access` in the IR
    result += sample_texture(texture_array[uniform_index], sampler_array[uniform_index], uv);
    result += load_texture(texture_array[uniform_index]);

    // the same handle used both directly and as a call argument
    result += textureSampleLevel(texture_array[0], sampler_array[0], uv, 0.0);

    // non-bindless handles still work
    result += sample_texture(single_texture, sampler_array[0], uv);

    return result;
}
