# Approximated Nyuzi Processor

This repository was created in the course of the bachelor thesis by Daniel Blattner, e12020646@student.tuwien.ac.at under supervision of Dr. Nima TaheriNejad, nima.taherinejad@tuwien.ac.at.

The work is a modification of the GPGPU processor [Nyuzi](https://github.com/jbush001/NyuziProcessor) by Jeff Bush. The floating-point multiplier within the core was replaced with an approximated floating-point multiplier. The employed approximation techniques are the [DTCL](https://doi.org/10.1109/ISQED57927.2023.10129296) by Mishra et al. and the [FPLM](https://doi.org/10.1145/3453688.3461509) Zijing et al. 

## Installation

Please follow the installation guide given in the [Nyuzi](https://github.com/jbush001/NyuziProcessor) repository. 

Currently there is a problem with the installlation of the [NyuziToolchain](https://github.com/jbush001/NyuziToolchain) (as seen in the [Issue #204](https://github.com/jbush001/NyuziProcessor/issues/204) and [Issue #110](https://github.com/jbush001/NyuziToolchain/issues/110)). It is therefore recommended to use the Docker image https://hub.docker.com/r/jeffbush001/nyuzi-build to build the project. 
