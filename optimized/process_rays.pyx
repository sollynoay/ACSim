# cython: boundscheck=False, wraparound=False, nonecheck=True
import numpy as np
cimport numpy as np
from cython.parallel import prange
from libc.math cimport sqrt, pow
cimport cython

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
def process_hits_openmp(
    np.ndarray[np.float64_t, ndim=2] ray_directions,
    np.ndarray[np.float64_t, ndim=2] ray_origins,
    np.ndarray[np.float64_t, ndim=2] hit_loc_list,
    np.ndarray[np.float64_t, ndim=2] hit_norm_list,
    np.ndarray[np.int32_t, ndim=1] hit_obj_list,
    np.ndarray[np.uint8_t, ndim=1] has_hit_list,
    np.ndarray[np.int32_t, ndim=2] pixel_coords_hit_list,
    np.ndarray[np.float64_t, ndim=3] buf_dist,
    np.ndarray[np.float64_t, ndim=3] buf_hitloc,
    np.ndarray[np.float64_t, ndim=3] buf_light,
    np.ndarray[np.float64_t, ndim=3] buf_c,
    np.ndarray[np.float64_t, ndim=3] buf_br,
    dict blender_to_trimesh_mapping,
    np.ndarray[np.float64_t, ndim=1] light_color,
    np.ndarray[np.float64_t, ndim=1] light_loc,
    np.ndarray[np.float64_t, ndim=2] obj_color,
    int depth
):
    cdef Py_ssize_t i, j
    cdef int x, y
    cdef double dist, light_dist, cos_theta, mag, norm_hit_norm
    cdef double I_light, I_diffuse, temp_cos_theta, temp_diffuse
    cdef double ray_dir[3], ray_orig[3], hit_loc[3], light_vec[3], hit_norm[3]
    cdef double diffuse_intensity, light_intensity, temp_I_light

    # Parallel loop with OpenMP
    for i in prange(ray_directions.shape[0], nogil=True):
        if has_hit_list[i] != 0:
            # Initialize ray direction, origin, and hit location
            for j in range(3):
                ray_dir[j] = ray_directions[i, j]
                ray_orig[j] = ray_origins[i, j]
                hit_loc[j] = hit_loc_list[i, j]
                hit_norm[j] = hit_norm_list[i, j]

            # Pixel coordinates
            x = pixel_coords_hit_list[i, 0]
            y = pixel_coords_hit_list[i, 1]

            # Calculate distance
            dist = sqrt(
                (hit_loc[0] - ray_orig[0]) ** 2 +
                (hit_loc[1] - ray_orig[1]) ** 2 +
                (hit_loc[2] - ray_orig[2]) ** 2
            )
            buf_dist[y, x, depth] = dist

            # Save hit location
            for j in range(3):
                buf_hitloc[y, x, j] = hit_loc[j]
            
            # Flip normal if needed
            cos_theta = (
                ray_dir[0] * hit_norm[0] +
                ray_dir[1] * hit_norm[1] +
                ray_dir[2] * hit_norm[2]
            )
            if cos_theta > 0:
                for j in range(3):
                    hit_norm[j] *= -1

            # Normalize hit_norm
            norm_hit_norm = sqrt(
                hit_norm[0] ** 2 +
                hit_norm[1] ** 2 +
                hit_norm[2] ** 2
            )
            for j in range(3):
                hit_norm[j] /= norm_hit_norm

            # Initialize light vector and calculate light distance
            for j in range(3):
                light_vec[j] = light_loc[j]-hit_loc[j] 
            light_dist = sqrt(
                light_vec[0] ** 2 +
                light_vec[1] ** 2 +
                light_vec[2] ** 2
            )
            buf_light[y, x, depth] = light_dist

            # Normalize light_vec
            for j in range(3):
                light_vec[j] /= light_dist

            # Initialize thread-local light intensity and diffuse intensity
            light_intensity = light_color[0]  
            diffuse_intensity = obj_color[i,0]


            # Calculate diffuse lighting
            cos_theta = (
                light_vec[0] * hit_norm[0] +
                light_vec[1] * hit_norm[1] +
                light_vec[2] * hit_norm[2]
            )
            if cos_theta > 0:
                # Thread-local intermediate calculations
                mag = light_dist
                temp_I_light = 4.0 * mag * mag * pow(10.0, (1.95 * mag / 10.0))
                if temp_I_light != 0.0:  # Avoid division by zero
                    I_light = light_intensity / temp_I_light
                    I_light *= pow(10.0, (64.0 / 10.0))
                else:
                    I_light = 0.0

                temp_cos_theta = pow(cos_theta, 2.0)  # Thread-local
                temp_diffuse = diffuse_intensity * I_light  # Thread-local
                I_diffuse = temp_diffuse * temp_cos_theta  # Thread-local

                # Store results in buffers
                buf_c[y, x, depth] = I_diffuse * pow(1.0, (1.0 - depth))
                buf_br[y, x, depth] = 0  # Replace with actual back reflectivity
