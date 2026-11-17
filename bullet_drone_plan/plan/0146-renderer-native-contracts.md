# 0146: Renderer native contracts

## Goal
Build the packaged Godot viewer without a sibling `bullet_msgs` checkout and keep its pose, camera, and image transport compatible with the protocol packages in `bullet_drone/libs`.

## Implementation steps
- Put the renderer's C++ transport headers in its own source tree and remove CMake's `../bullet_msgs/include` path.
- Add packaged-viewer handling for current pose and camera-info telemetry and publish version-3 image descriptors with the pose header and drone ID.
- Pass the active Python interpreter from `external_render/build.py` to CMake, avoiding the removed shared environment path. Allow a source export without Git metadata to record an unknown source revision, and stage the terrain path used by the separated renderer checkout.

## Interfaces
The Godot adapter's `start` method accepts an optional `viewer_only` Boolean. Existing one-argument editor calls retain their behavior. The image notification keeps the existing topic and SHM layout and adds version-3 `header` and `drone_id` fields for packaged-viewer captures.

## Verification
Native CMake build and a C++-to-Python version-3 descriptor check pass in a writable mirror. The packaging script reaches Godot export; export and a rendered flight remain pending because matching Linux export templates are not installed in this environment.

## Scope and defaults
The packaged viewer is the target. Legacy editor controls, Python tools, recorder schemas, and the renderer's Python `bullet-msgs` dependency remain for a separate migration.

## Status
Prepared; destination apply and runtime verification pending. Implementation commit: Pending.
