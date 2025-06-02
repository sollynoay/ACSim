import numpy as np
cimport numpy as np
from libc.math cimport fabs
from cython.parallel import prange

def compute_intersections(
    np.ndarray[np.float64_t, ndim=2, mode='c'] ray_origins,
    np.ndarray[np.float64_t, ndim=2, mode='c'] ray_directions,
    np.ndarray[np.float64_t, ndim=3, mode='c'] triangles,
    np.ndarray[np.float64_t, ndim=2, mode='c'] normals,
    np.ndarray[np.int32_t, ndim=1, mode='c'] object_ids,
    np.ndarray[np.int32_t, ndim=1, mode='c'] first_hit_indices,
    np.ndarray[np.int32_t, ndim=2, mode='c'] pixel_coords  # Add pixel coordinates as input
):
    cdef int num_rays = ray_origins.shape[0]
    cdef int i, tri_idx

    # Allocate thread-local storage for valid intersections
    cdef np.ndarray[np.int32_t, ndim=1, mode='c'] thread_has_hit = np.zeros(num_rays, dtype=np.int32)
    cdef np.ndarray[np.float64_t, ndim=2, mode='c'] thread_hit_loc = np.empty((num_rays, 3), dtype=np.float64)
    cdef np.ndarray[np.float64_t, ndim=2, mode='c'] thread_hit_norm = np.empty((num_rays, 3), dtype=np.float64)
    cdef np.ndarray[np.int32_t, ndim=1, mode='c'] thread_index = np.full(num_rays, -1, dtype=np.int32)
    cdef np.ndarray[np.int32_t, ndim=1, mode='c'] thread_hit_obj = np.full(num_rays, -1, dtype=np.int32)
    cdef np.ndarray[np.int32_t, ndim=2, mode='c'] thread_pixel_coords = np.full((num_rays, 2), -1, dtype=np.int32)  # Pixel coordinates

    # Use memory views for safe access
    cdef const double[:, :] ray_origins_mv = ray_origins
    cdef const double[:, :] ray_directions_mv = ray_directions
    cdef const double[:, :, :] triangles_mv = triangles
    cdef const double[:, :] normals_mv = normals
    cdef const int[:] object_ids_mv = object_ids
    cdef const int[:] first_hit_indices_mv = first_hit_indices
    cdef const int[:, :] pixel_coords_mv = pixel_coords  # Memory view for (i, j)

    # C variables
    cdef double[3] ray_origin, ray_direction, intersection_point, normal
    cdef double[3][3] triangle
    cdef int pixel_x, pixel_y

    # Parallel loop
    for i in prange(num_rays, nogil=True, schedule='dynamic'):
        tri_idx = first_hit_indices_mv[i]

        # Skip invalid indices
        if tri_idx < 0 or tri_idx >= triangles_mv.shape[0]:
            continue

        # Copy ray origin, direction, and pixel coordinates
        ray_origin[0], ray_origin[1], ray_origin[2] = ray_origins_mv[i, 0], ray_origins_mv[i, 1], ray_origins_mv[i, 2]
        ray_direction[0], ray_direction[1], ray_direction[2] = ray_directions_mv[i, 0], ray_directions_mv[i, 1], ray_directions_mv[i, 2]
        pixel_x, pixel_y = pixel_coords_mv[i, 0], pixel_coords_mv[i, 1]

        # Copy triangle vertices
        triangle[0][0], triangle[0][1], triangle[0][2] = triangles_mv[tri_idx, 0, 0], triangles_mv[tri_idx, 0, 1], triangles_mv[tri_idx, 0, 2]
        triangle[1][0], triangle[1][1], triangle[1][2] = triangles_mv[tri_idx, 1, 0], triangles_mv[tri_idx, 1, 1], triangles_mv[tri_idx, 1, 2]
        triangle[2][0], triangle[2][1], triangle[2][2] = triangles_mv[tri_idx, 2, 0], triangles_mv[tri_idx, 2, 1], triangles_mv[tri_idx, 2, 2]

        # Compute intersection point
        if compute_ray_triangle_intersection_cy(ray_origin, ray_direction, triangle, intersection_point):
            # Mark as hit
            thread_has_hit[i] = 1

            # Store intersection point
            thread_hit_loc[i, 0] = intersection_point[0]
            thread_hit_loc[i, 1] = intersection_point[1]
            thread_hit_loc[i, 2] = intersection_point[2]

            # Store normal
            normal[0], normal[1], normal[2] = normals_mv[tri_idx, 0], normals_mv[tri_idx, 1], normals_mv[tri_idx, 2]
            thread_hit_norm[i, 0] = normal[0]
            thread_hit_norm[i, 1] = normal[1]
            thread_hit_norm[i, 2] = normal[2]

            # Store triangle index
            thread_index[i] = tri_idx

            # Store object ID
            thread_hit_obj[i] = object_ids_mv[tri_idx]

            # Store pixel coordinates
            thread_pixel_coords[i, 0] = pixel_x
            thread_pixel_coords[i, 1] = pixel_y

    return thread_has_hit.astype(bool), thread_hit_loc, thread_hit_norm, thread_index, thread_hit_obj, thread_pixel_coords




# Internal helper function for ray-triangle intersection
cdef inline bint compute_ray_triangle_intersection_cy(
    double[3] ray_origin,
    double[3] ray_direction,
    double[3][3] triangle,
    double[3] intersection_point
) nogil:
    """
    Compute the intersection of a ray and a triangle using the Möller–Trumbore algorithm.
    Returns True if there is an intersection, False otherwise.
    """
    cdef double epsilon = 1e-6
    cdef double vertex0[3], vertex1[3], vertex2[3]
    cdef double edge1[3], edge2[3], h[3], s[3], q[3]
    cdef double a, f, u, v, t

    # Extract triangle vertices
    vertex0[0], vertex0[1], vertex0[2] = triangle[0][0], triangle[0][1], triangle[0][2]
    vertex1[0], vertex1[1], vertex1[2] = triangle[1][0], triangle[1][1], triangle[1][2]
    vertex2[0], vertex2[1], vertex2[2] = triangle[2][0], triangle[2][1], triangle[2][2]

    # Compute edges
    edge1[0] = vertex1[0] - vertex0[0]
    edge1[1] = vertex1[1] - vertex0[1]
    edge1[2] = vertex1[2] - vertex0[2]

    edge2[0] = vertex2[0] - vertex0[0]
    edge2[1] = vertex2[1] - vertex0[1]
    edge2[2] = vertex2[2] - vertex0[2]

    # Cross product of ray direction and edge2
    h[0] = ray_direction[1] * edge2[2] - ray_direction[2] * edge2[1]
    h[1] = ray_direction[2] * edge2[0] - ray_direction[0] * edge2[2]
    h[2] = ray_direction[0] * edge2[1] - ray_direction[1] * edge2[0]

    # Compute determinant
    a = edge1[0] * h[0] + edge1[1] * h[1] + edge1[2] * h[2]
    if fabs(a) < epsilon:
        return False  # Ray is parallel to the triangle

    f = 1.0 / a
    s[0] = ray_origin[0] - vertex0[0]
    s[1] = ray_origin[1] - vertex0[1]
    s[2] = ray_origin[2] - vertex0[2]

    # Compute barycentric coordinate u
    u = f * (s[0] * h[0] + s[1] * h[1] + s[2] * h[2])
    if u < 0.0 or u > 1.0:
        return False

    # Cross product of s and edge1
    q[0] = s[1] * edge1[2] - s[2] * edge1[1]
    q[1] = s[2] * edge1[0] - s[0] * edge1[2]
    q[2] = s[0] * edge1[1] - s[1] * edge1[0]

    # Compute barycentric coordinate v
    v = f * (ray_direction[0] * q[0] + ray_direction[1] * q[1] + ray_direction[2] * q[2])
    if v < 0.0 or u + v > 1.0:
        return False

    # Compute intersection distance t
    t = f * (edge2[0] * q[0] + edge2[1] * q[1] + edge2[2] * q[2])
    if t > epsilon:  # Valid intersection
        intersection_point[0] = ray_origin[0] + t * ray_direction[0]
        intersection_point[1] = ray_origin[1] + t * ray_direction[1]
        intersection_point[2] = ray_origin[2] + t * ray_direction[2]
        return True

    return False
