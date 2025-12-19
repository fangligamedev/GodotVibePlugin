# 3D Breakout Game - Design Document

## 1. Game Overview
A simple 3D arcade game where the player controls a paddle to bounce a ball and destroy bricks.

## 2. Core Mechanics
- **Paddle (Player):** 
  - CharacterBody3D.
  - Moves Left/Right (X-axis) based on input.
- **Ball:** 
  - RigidBody3D.
  - Bounces off walls, paddle, and bricks physically.
  - Needs a PhysicsMaterial with high bounce and low friction.
- **Bricks:** 
  - StaticBody3D (mostly).
  - Detected by the ball/area and destroyed on impact.
- **Game Loop:** 
  - Ball launches -> Bricks destroyed -> Win condition (all bricks gone) or Lose condition (ball falls below paddle).

## 3. Project Structure
- `res://scripts/`: Contains GDScript files.
  - `paddle.gd`: Player movement.
  - `ball.gd`: Ball initialization and boundary checks.
  - `brick.gd`: Handle destruction.
  - `game_manager.gd`: Global state (score, game over).
- `res://scenes/`: 
  - `main.tscn`: The level layout (Camera, Walls, Lights).
  - `paddle.tscn`: Player prefab.
  - `ball.tscn`: Ball prefab.
  - `brick.tscn`: Brick prefab.
- `res://materials/`: StandardMaterial3D resources (colors).

## 4. Implementation Steps
1. **Setup Structure:** Create directories.
2. **Paddle:** Create scene and script.
3. **Ball:** Create scene, physics material, and script.
4. **Brick:** Create scene and script.
5. **Main Level:** Setup camera, walls, lighting, and spawn bricks.
6. **Game Loop:** Connect logic for win/lose states.
