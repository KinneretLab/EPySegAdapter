from typing import List, Tuple

import numpy as np
import scipy.ndimage
from tifffile import tifffile


class ExtraInfoExtractor:
    def __init__(self):
        self._img: np.ndarray = np.zeros(0)
        self._vertices: np.ndarray = np.zeros(0)
        self._bonds: np.ndarray = np.zeros(0)
        self._img_size: int = 0
        self._dims: int = 1

    def register_image(self, full_img_path):
        self._img = tifffile.imread(full_img_path)
        if self._img.ndim == 3:
            self._dims = 3
            self._img = self._img[1, :, :]
        self._img[self._img > 0] = 1  # turn image to binary
        self._img_size = len(self._img)
        self._img[0, :] = self._img[:, 0] = self._img[:, self._img_size - 1] = self._img[self._img_size - 1, :] = 1
        self._vertices: np.ndarray = np.zeros(0)
        self._bonds: np.ndarray = np.zeros(0)

    def fix_segmentation(self) -> np.ndarray:
        diamond_kernel = [[0, 1, 0], [1, 0, 1], [0, 1, 0]]
        mask = self._img
        mask[0, :] = mask[:, 0] = mask[:, self._img_size - 1] = mask[self._img_size - 1, :] = 0
        for i in range(1, self._img_size - 1):
            for j in range(1, self._img_size - 1):  # single pass, but do not go through image edges
                if mask[i, j] == 0:
                    # to check if a point is a 1 pixel cell, we load its 3x3 pixel area,
                    # multiply it by the diamond kernel and check if the diamond is fulfilled.
                    # If it is, the pixel is filled.
                    kernel = self._get_kernel(i, j)
                    # take care of square vertices
                    if (diamond_kernel * kernel).sum() == 4:
                        self._img[i, j] = mask[i, j] = 1
        ret = 255 * mask
        self._img[0, :] = self._img[:, 0] = self._img[:, self._img_size - 1] = self._img[self._img_size - 1, :] = 1
        if self._dims == 3:
            return np.stack([ret, ret, ret])
        else:
            return ret

    def calc_vertices(self) -> np.ndarray:
        mask = np.zeros((self._img_size, self._img_size)).astype(np.uint8)
        square_kernel = np.array([[0, 0, 0], [0, 1, 1], [0, 1, 1]])
        plus_kernel = [[0, 1, 0], [1, 1, 1], [0, 1, 0]]
        for i in range(1, self._img_size - 1):
            for j in range(1, self._img_size - 1):  # single pass, but do not go through image edges
                if self._img[i, j] == 1:
                    # to check if a point is a vertex, we load its 3x3 pixel area and
                    # split the black pixels into groups.
                    # If there are at least 3 separate groups, the candidate must be a vertex.
                    kernel = self._get_kernel(i, j)
                    labels = scipy.ndimage.measurements.label(np.logical_not(kernel), plus_kernel)
                    # take care of square vertices
                    if np.max(labels[0]) >= 3 or (square_kernel * kernel).sum() == 4:
                        mask[i, j] = 255
        self._vertices = mask
        return mask

    def calc_bonds(self) -> np.ndarray:
        if len(self._vertices) != self._img_size:
            self.calc_vertices()
        self._bonds = np.tile(self._img * 255, [3, 1, 1])
        j = 0
        i = 0
        infect_stack: List[Tuple[int, int, int, bool]] = []
        bond_index = 0
        while j != self._img_size:
            while len(infect_stack) != 0:  # resolve infections
                infect_data = infect_stack.pop()
                if infect_data[0] == -1:
                    bond_index -= 1
                else:
                    for new_infect in self._infect(infect_data[0], infect_data[1], infect_data[2], infect_data[3]):
                        infect_stack.append(new_infect)
            if (self._bonds[:, i, j] == [255, 255, 255]).all() and not self._vertices[i, j] == 255:
                infect_stack.append((i, j, bond_index, False))
                bond_index += 1
            i += 1
            if i == self._img_size:
                i = 0
                j += 1
        while len(infect_stack) != 0:  # resolve infections for the last time
            infect_data = infect_stack.pop()
            if infect_data[0] != -1:
                for new_infect in self._infect(infect_data[0], infect_data[1], infect_data[2], infect_data[3]):
                    infect_stack.append(new_infect)
        return self._bonds

    def _infect(self, i, j, bond_index, infect_if_square) -> List[Tuple[int, int, int, bool]]:
        """
        infects a pixel, meaning it marks it with a particular ID to color, and colors
        white pixels that are part of the same bond with the same color (that are not vertices)
        :param i: X coordinate of pixel to infect
        :param j: Y coordinate of pixel to infect
        """

        # check if pixel is part of a square. If so, it is the final cell to infect.
        squares = np.array([[[0, 0, 0], [1, 1, 0], [1, 1, 0]],
                            [[1, 1, 0], [1, 1, 0], [0, 0, 0]],
                            [[0, 1, 1], [0, 1, 1], [0, 0, 0]]])
        if ((squares * self._get_kernel(i, j)).sum(1).sum(1) == 4).any():
            if infect_if_square:
                self._bonds[:, i, j] = [(bond_index >> 16) & 255,
                                        (bond_index >> 8) & 255, bond_index & 255]
                return []
            else:
                return [(-1, -1, -1, False)]

        # converts int to RGB
        self._bonds[:, i, j] = [(bond_index >> 16) & 255, (bond_index >> 8) & 255, bond_index & 255]
        # generate list of indices to test for infection
        ii, jj = np.meshgrid(np.linspace(i - 1, i + 1, 3).astype(np.int16),
                             np.linspace(j - 1, j + 1, 3).astype(np.int16))
        ii = ii.flatten()
        jj = jj.flatten()
        neighbors: List[Tuple[int, int, int, bool]] = [(ii[k], jj[k], bond_index, True) for k in range(9)]
        # remove entries from list based on out-of-bounds
        neighbors = list(filter(lambda coord: 0 <= coord[0] < self._img_size and 0 <= coord[1] < self._img_size,
                                neighbors))
        # remove entries from list if they are zeros or already infected
        neighbors = list(filter(lambda coord: (self._bonds[:, coord[0], coord[1]] == [255, 255, 255]).all(), neighbors))
        # remove entries from list if there is a closer infect-able cell
        # Iteration on a tier 2 copy. It is a very bad idea to iterate on a list you are directly changing.
        for ii, jj, _, _ in neighbors[:]:
            # ii and jj are no longer numpy stuff, but integers related to i,j (not relative though)
            # prevent infection of cells that are seperated by an infectable,
            # but close enough to be rendered in the kernel
            if i == ii:
                neighbors = list(filter(lambda coord: coord[1] != jj or coord[0] == ii, neighbors))
            if j == jj:
                neighbors = list(filter(lambda coord: coord[0] != ii or coord[1] == jj, neighbors))
            if self._vertices[ii, jj] == 255:
                # vertices should not be infected
                neighbors = list(filter(lambda coord: coord[0] != ii or coord[1] != jj, neighbors))
        # return remaining infectable entries (should be 1 or 2)
        return neighbors

    def _get_kernel(self, i, j) -> np.ndarray:
        kernel = np.zeros((3, 3))
        kernel[i == 0:3 - (i == self._img_size - 1), j == 0:3 - (j == self._img_size - 1)] += \
            self._img[max(i - 1, 0):min(i + 1, self._img_size - 1) + 1,
                      max(j - 1, 0):min(j + 1, self._img_size - 1) + 1]
        return kernel
