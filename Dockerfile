# Created based on this https://github.com/mochi-hpc-experiments/platform-configurations/blob/main/ANL/Polaris-Apptainer/mochi-apptainer.def

FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV SPACK_ROOT=/spack
ENV LD_LIBRARY_PATH=/spack/var/spack/environments/mochi/.spack-env/view/lib:/spack/var/spack/environments/mochi/.spack-env/view/lib64:$LD_LIBRARY_PATH
ENV PATH=/spack/var/spack/environments/mochi/.spack-env/view/bin:$PATH

# Install required system dependencies
RUN apt-get update --fix-missing && apt-get install -y \
    build-essential gfortran wget \
    python3 python3-pip gcc git \
    ca-certificates coreutils curl \
    unzip zip bzip2 xz-utils \
    python3-setuptools \
    automake cmake libtool pkgconf autoconf \
    bison fuse sudo vim \
    apt-utils net-tools iptables iputils-ping iproute2 \
    libssl-dev time && \
    apt-get clean

# Install the latest development version of Spack
RUN git clone -b develop -c feature.manyFiles=true --depth 1 https://github.com/spack/spack.git /spack && \
    . /spack/share/spack/setup-env.sh && \
    spack bootstrap now

# Clone the Mochi Spack package repository
RUN git clone https://github.com/mochi-hpc/mochi-spack-packages.git /usr/mochi-spack-packages

# Set up Spack environment and buildcache
RUN . /spack/share/spack/setup-env.sh && \
    spack mirror add --unsigned mochi-buildcache oci://ghcr.io/mochi-hpc/mochi-spack-buildcache && \
    spack repo add /usr/mochi-spack-packages && \
    spack external find && \
    spack env create mochi && \
    spack env activate mochi && \
    # Added the following to attempt to build it
    sed -i 's/# concretizer: unify/concretizer: when_possible/' /spack/etc/spack/defaults/config.yaml && \
    spack add mofka@main+python+mpi ^mochi-bedrock ^mpich@3.4 ^mercury~boostsys~checksum ^libfabric@1.19.1 ^json-c@0.13.0 %gcc@13 && \
    spack add mochi-margo ^mercury~boostsys~checksum ^libfabric@1.19.1 ^json-c@0.13.0 && \
    spack concretize -f --fresh && \
    spack env depfile -o Makefile.env && \
    make -j 64 -f Makefile.env && \
    ldconfig

# Validate installation
RUN . /spack/share/spack/setup-env.sh && \
    spack env activate mochi && \
    which margo-info && margo-info

