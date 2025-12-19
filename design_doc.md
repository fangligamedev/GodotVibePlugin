# 3D Breakout Game Design Document

## 1. Game Overview
A classic breakout style game featuring 3D graphics. The player controls a paddle to bounce a ball and destroy a grid of bricks.

## 2. Project Structure
- Root: `res://` (mapped to `test1`)
- Scenes: `res://scenes/`
- Scripts: `res://scripts/`

## 3. Key Components
### A. Paddle (`Paddle.tscn`)
- Type: CharacterBody3D
- Shape: BoxShape3D
- Logic: Moves left/right based on input.

### B. Ball (`Ball.tscn`)
- Type: CharacterBody3D
- Shape: SphereShape3D
- Logic: Constant speed, bounces off walls/paddle, destroys bricks.

### C. Brick (`Brick.tscn`)
- Type: StaticBody3D
- Shape: BoxShape3D
- Logic: Disappears when hit.

### D. Main Scene (`Main.tscn`)
- Contains: Paddle, Ball, Walls, Brick spawner logic, Camera.

## 4. Controls
- Move: Left/Right Arrows or A/D
- Start/Launch: Space