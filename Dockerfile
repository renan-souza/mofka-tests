FROM continuumio/miniconda3 AS base

RUN apt-get update --fix-missing && apt-get install -y \
    build-essential gfortran wget \
    python3 python3-pip gcc git \
    ca-certificates coreutils curl \
    unzip zip bzip2 xz-utils \
    python3-setuptools \
    automake cmake libtool pkgconf autoconf \
    bison fuse sudo vim \
    apt-utils net-tools iptables iputils-ping iproute2 \
    libssl-dev time \
    libzmq3-dev \
    swig \
    libmpich-dev \
    libhdf5-mpich-dev \
    nano \
    libpmem-dev libuv1

RUN conda install -y \
    python=3.11 \
    numpy \
    scipy \
    matplotlib \
    pyzmq \
    pip \
    cmake

RUN pip install --upgrade pip

# Clone Spack
RUN git clone -b develop -c feature.manyFiles=true --depth 1 https://github.com/spack/spack.git /spack

# Bootstrap Spack
RUN . /spack/share/spack/setup-env.sh && spack bootstrap now

# Disable SSL verification in Spack
RUN sed -i 's/  verify_ssl: true/  verify_ssl: false/' /spack/etc/spack/defaults/config.yaml

# Clone external package repository for Mochi
RUN git clone https://github.com/mochi-hpc/mochi-spack-packages.git /usr/mochi-spack-packages

# Set up Spack environment and install packages
RUN . /spack/share/spack/setup-env.sh \
    && spack mirror add --unsigned mochi-buildcache oci://ghcr.io/mochi-hpc/mochi-spack-buildcache \
    && spack repo add /usr/mochi-spack-packages \
    && spack external find \
    && spack env create mochi \
    && spack env activate mochi \
    && spack add mofka@main+python+mpi ^mochi-bedrock ^mpich@3.4 ^mercury~boostsys~checksum ^libfabric@1.19.1 ^json-c@0.13.0 \
    && time spack concretize -f --fresh \
    && spack install mofka
