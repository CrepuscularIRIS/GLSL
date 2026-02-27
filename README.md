# BSL enhanced for 1.7.10

This repository documents our hands-on GLSL shader learning process centered on **BSL enhanced for 1.7.10** through practical integration experiments.

The project focuses on understanding shader architecture, adapting configurations, and validating visual behavior across multiple shader packs. It is intended for study, technical exploration, and reproducible experiments.

## Project Scope

We use this repository to:
- Study how real-world shader packs organize rendering pipelines.
- Port and adapt selected visual ideas across different packs.
- Compare behavior by dimension and scenario (night, rain, reflection, water surface).
- Record configuration and implementation decisions in a reproducible way.

This is a learning and experimentation project. The goal is technical understanding and controlled adaptation, not code copying for redistribution.

## Current Experiment Highlights

### 1. LUX Aurora Integration
- Integrated aurora-style atmospheric behavior inspired by LUX workflows.
- Verified night-dependent visibility and weather attenuation behavior.
- Applied aurora blending in sky rendering and reflection-related passes.
- Tuned intensity so aurora remains visible without overwhelming base sky color.

### 2. Water Surface Tuning
- Tuned water reflection response for clearer sky coupling at night.
- Improved Fresnel/sky reflection balance for better readability on calm water.
- Adjusted reflection multiplier strategy to avoid overbright highlights.

### 3. Photon-Style Water Wave Integration
- Integrated Photon-style wave behavior into water surface experimentation.
- Compared wave shape and motion against baseline water implementations.
- Evaluated visual consistency under different lighting conditions.

### 4. Dimension-Oriented Behavior Experiments
- Tested different visual strategies by world context (e.g., normal overworld cycle vs. always-night style setup).
- Explored dimension-specific choices for aurora visibility and water look.
- Evaluated how sky/atmosphere changes affect reflection coherence.

### 5. End Atmosphere Direction
- Investigated End dimension atmosphere effects inspired by modern cinematic shader styles.
- Researched beam/fog/glow composition and nebula-like visual layering.
- Kept this branch experimental and learning-oriented while validating feasibility.

## Repository Structure

Top-level folders currently include multiple shader-pack references and working targets used for comparative learning, tuning, and effect validation.

Examples in this workspace include:
- `Complementary/`
- `LUX/`
- `Photon/`
- `Solas/`

Some source folders are intentionally excluded from version tracking to keep this repository aligned with our learning scope and publishing rules.

## How We Work

Our workflow is iterative:
1. Read and trace target shader stages (sky, deferred, water, atmosphere).
2. Isolate one visual feature to adapt.
3. Integrate with minimal changes and test in controlled scenes.
4. Tune parameters (visibility, intensity, reflection, weather interaction).
5. Document what worked, what failed, and why.

## Technical Focus Areas

- Atmospheric scattering and sky composition
- Aurora visibility logic (night/rain gating)
- Water normals, wave modeling, and reflection mixing
- Deferred pass color composition
- Dimension-specific rendering behavior
- Legacy GLSL compatibility constraints in shader mod environments

## Notes and Positioning

- This repository is maintained as a GLSL learning notebook in code form.
- We prioritize understanding shader configuration, parameterization, and rendering logic.
- The content is organized for experimentation, documentation, and future iteration.

## Status

Active and evolving. New experiments and refinements are added as we validate each rendering feature in practice.
