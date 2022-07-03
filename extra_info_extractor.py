from typing import List, Tuple

import numpy as np
import scipy.ndimage
from tifffile import tifffile


class ExtraInfoExtractor:
    def __init__(self):
        self._img: np.ndarray = np.zeros(0)
        self._bond_index: int = 0
        self._vertices: np.ndarray = np.zeros(0)
        self._bonds: np.ndarray = np.zeros(0)
        self._img_size: int = 0

    def register_image(self, full_img_path):
        self._img = tifffile.imread(full_img_path)[:, :]
        self._img[self._img > 0] = 1  # turn image to binary
        self._bond_index = 0
        self._img_size = len(self._img)
        self._vertices: np.ndarray = np.zeros(0)
        self._bonds: np.ndarray = np.zeros(0)

    def calc_vertices(self) -> np.ndarray:
        mask = np.zeros((self._img_size, self._img_size)).astype(np.uint8)
        for i in range(0, self._img_size):
            for j in range(0, self._img_size):
                if self._img[i, j] == 1:
                    # to check if a point is a vertex, we load its 3x3 pixel area and
                    # split the black pixels into groups.
                    # If there are at least 3 separate groups, the candidate must be a vertex.
                    kernel = np.zeros((3, 3))
                    kernel[i == 0:3 - (i == self._img_size - 1), j == 0:3 - (j == self._img_size - 1)] += \
                        self._img[max(i - 1, 0):min(i + 1, self._img_size - 1) + 1,
                                  max(j - 1, 0):min(j + 1, self._img_size - 1) + 1]
                    labels = scipy.ndimage.measurements.label(np.logical_not(kernel), [[0, 1, 0], [1, 1, 1], [0, 1, 0]])
                    if np.max(labels[0]) >= 3:
                        mask[i, j] = 255
        self._vertices = mask
        return mask

    def calc_bonds(self) -> np.ndarray:
        if len(self._vertices) != self._img_size:
            self.calc_vertices()
        self._bonds = np.tile(self._img * 255, [3, 1, 1])
        for j in range(0, self._img_size):
            for i in range(0, self._img_size):
                if (self._bonds[:, i, j] == [255, 255, 255]).all() and not self._vertices[i, j] == 255:
                    self._bond_index += 1
                    self._infect(i, j)
        return self._bonds

    def _infect(self, i, j) -> None:
        """
        infects a pixel, meaning it marks it with a particular ID to color, and colors
        white pixels that are part of the same bond with the same color (that are not vertices)
        :param i: X coordinate of pixel to infect
        :param j: Y coordinate of pixel to infect
        """
        # converts int to RGB
        self._bonds[:, i, j] = [(self._bond_index >> 16) & 255, (self._bond_index >> 8) & 255, self._bond_index & 255]
        # generate list of indices to test for infection
        ii, jj = np.meshgrid(np.linspace(i - 1, i + 1, 3).astype(np.int),
                             np.linspace(j - 1, j + 1, 3).astype(np.int))
        ii = ii.flatten()
        jj = jj.flatten()
        neighbors: List[Tuple[int, int]] = [(ii[k], jj[k]) for k in range(9)]
        # remove entries from list based on out-of-bounds
        neighbors = list(filter(lambda coord: 0 <= coord[0] < self._img_size and 0 <= coord[1] < self._img_size,
                                neighbors))
        # remove entries from list based on vertices
        # Iteration on a tier 2 copy. It is a very bad idea to iterate on a list you are directly changing.
        for ii, jj in neighbors[:]:
            # ii and jj are no longer numpy stuff, but integers related to i,j (not relative though)
            if self._vertices[ii, jj] == 255:
                # prevent infection of cells that are seperated by a vertex,
                # but close enough to be rendered in the kernel
                if i == ii:
                    neighbors = list(filter(lambda coord: coord[1] != jj, neighbors))
                if j == jj:
                    neighbors = list(filter(lambda coord: coord[0] != ii, neighbors))
                # vertices should not be infected
                neighbors = list(filter(lambda coord: coord[0] != ii or coord[1] != jj, neighbors))
        # remove entries from list if they are zeros or already infected
        neighbors = list(filter(lambda coord: (self._bonds[:, coord[0], coord[1]] == [255, 255, 255]).all(), neighbors))
        # infect remaining entries (should be 1 or 2)
        for ii, jj in neighbors:
            self._infect(ii, jj)
