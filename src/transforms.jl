"""
`CALCULATE_AFFINE` - Compute left-hand affine transform from two Nxd point sets

```
tform = calculate_affine(moving_pts, fixed_pts)
```

* moving_pts: 2D array, each row being nonhomogeneous coords of a point, of the 
    point set that is moving to fit the fixed point set.
* fixed_pts: 2D array, each row being nonhomogeneous coords of a point, of the 
    reference point set.
* tform: affine transformation that produces a mapping of the moving_pts to 
    fixed_pts.

```
fixed_pts = moving_pts * tform
```
"""
function calculate_affine(moving_pts, fixed_pts)
  moving = hcat(moving_pts, ones(size(moving_pts,1)))
  fixed = hcat(fixed_pts, ones(size(fixed_pts,1)))
  return moving \ fixed
end

"""
`CALCULATE_RIGID` - Compute left-hand rigid transform from two Nxd point sets

```
tform = calculate_rigid(moving_pts, fixed_pts)
```

* moving_pts: 2D array, each row being nonhomogeneous coords of a point, of the 
    point set that is moving to fit the fixed point set.
* fixed_pts: 2D array, each row being nonhomogeneous coords of a point, of the 
    reference point set.
* tform: rigid transformation that produces a mapping of the moving_pts to 
    fixed_pts.

```
fixed_pts = moving_pts * tform
```
"""
function calculate_rigid(moving_pts, fixed_pts)
  n, dim = size(moving_pts)
  moving_bar = mean(moving_pts, 1)
  fixed_bar = mean(fixed_pts, 1)
  moving_centered = moving_pts .- moving_bar
  fixed_centered = fixed_pts .- fixed_bar
  C = fixed_centered.' * moving_centered / n
  U,s,V = svd(C)
  # Rotation R in least squares sense: 
  # moving_pts - moving_bar = (fixed_pts - fixed_bar)*R
  R = (U * diagm(vcat(ones(dim-1), det(U*V.'))) * V.' ).'
  t = fixed_bar - moving_bar*R
  return [R zeros(dim); t 1]
end

"""
`CALCULATE_TRANSLATION` - Compute left-hand translation from two Nxd point sets

```
tform = calculate_translation(moving_pts, fixed_pts)
```

* moving_pts: 2D array, each row being nonhomogeneous coords of a point, of the 
    point set that is moving to fit the fixed point set.
* fixed_pts: 2D array, each row being nonhomogeneous coords of a point, of the 
    reference point set.
* tform: translation transformation that produces a mapping of the moving_pts to 
    fixed_pts.

```
fixed_pts = moving_pts * tform
```
"""
function calculate_translation(moving_pts, fixed_pts)
  n, dim = size(moving_pts)
  moving_bar = mean(moving_pts, 1)
  fixed_bar = mean(fixed_pts, 1)
  t = fixed_bar - moving_bar
  return [eye(2) zeros(dim); t 1]
end

function calculate_affine(matches::Matches)
  return calculate_affine(matches.src_points, matches.dst_points)
end

function calculate_rigid(matches::Matches)
  return calculate_rigid(matches.src_points, matches.dst_points)
end

function calculate_translation(matches::Matches)
  return calculate_translation(matches.src_points, matches.dst_points)
end

function calculate_affine(mesh::Mesh)
  return calculate_affine(mesh.src_nodes, mesh.dst_nodes)
end

function calculate_rigid(mesh::Mesh)
  return calculate_rigid(mesh.src_nodes, mesh.dst_nodes)
end

function calculate_translation(mesh::Mesh)
  return calculate_translation(mesh.src_nodes, mesh.dst_nodes)
end