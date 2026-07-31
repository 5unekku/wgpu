use wgpu_test::{
    gpu_test, GpuTestConfiguration, GpuTestInitializer, TestParameters, TestingContext,
};

pub fn all_tests(vec: &mut Vec<GpuTestInitializer>) {
    vec.push(UNSUBMITTED_QUEUE_WRITES_ARE_BOUNDED);
}

/// `Queue::write_buffer` stages each write in its own GPU allocation, which is only
/// freed once the submission consuming it has finished. An application that writes every
/// frame but only submits on some of them used to keep every skipped frame's staging
/// buffer around forever, growing until it ran the system out of memory. wgpu now submits
/// the pending writes on the user's behalf once enough of them have piled up.
///
/// See <https://github.com/gfx-rs/wgpu/issues/9354>.
#[gpu_test]
static UNSUBMITTED_QUEUE_WRITES_ARE_BOUNDED: GpuTestConfiguration = GpuTestConfiguration::new()
    .parameters(TestParameters::default())
    .run_sync(unsubmitted_queue_writes_are_bounded);

/// Enough writes to cross the auto-flush threshold several times over.
const WRITE_COUNT: usize = 4096;

fn unsubmitted_queue_writes_are_bounded(ctx: TestingContext) {
    let buffer = ctx.device.create_buffer(&wgpu::BufferDescriptor {
        label: Some("issue 9354 destination"),
        size: 64,
        usage: wgpu::BufferUsages::COPY_DST,
        mapped_at_creation: false,
    });
    let data = [0u8; 64];

    let live_buffers = || ctx.device.get_internal_counters().hal.buffers.read();

    let baseline = live_buffers();
    ctx.queue.write_buffer(&buffer, 0, &data);
    if live_buffers() <= baseline {
        // this backend doesn't track the counter we measure with, so there is nothing to
        // assert here
        return;
    }

    for _ in 1..WRITE_COUNT {
        ctx.queue.write_buffer(&buffer, 0, &data);
    }

    // the flush happens without us asking for it, but the staging buffers it hands over
    // are only freed once that submission has completed
    ctx.device
        .poll(wgpu::PollType::wait_indefinitely())
        .unwrap();

    let still_alive = live_buffers() - baseline;
    assert!(
        still_alive < WRITE_COUNT as isize / 2,
        "{still_alive} staging buffers are still alive after {WRITE_COUNT} unsubmitted writes",
    );
}
