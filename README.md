# FeA: Ferrum et Arcanum

A small experimental Godot prototype focused on first-person player movement, state-driven character control, and reusable projectile systems.

## Current Features

- Player controller built around a state machine
- Movement states for:
  - Walking
  - Running
  - Dashing
  - Jumping and air jumping
  - Wall running
  - Wall jumping
- Basic first-person projectile launching from the player’s point of view
- Projectile framework with separate movement and rotation components
- Multiple projectile collision detection modes:
  - Area-based collision
  - Raycast sweep (avoids tunnelling)
  - Shape sweep (avoids tunnelling)
- Hurtbox and hitbox definitions
- Camera effects such as view bobbing and FOV changes
- Small test level for experimenting with movement mechanics

<img width="1914" height="1076" alt="image" src="https://github.com/user-attachments/assets/ff4c6348-6e90-4118-8041-06cdd3bbdc45" />
<img width="1813" height="970" alt="image" src="https://github.com/user-attachments/assets/eeb36754-e63a-42ff-94b1-8fa2f320bc79" />
