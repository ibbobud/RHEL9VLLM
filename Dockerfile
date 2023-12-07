FROM registry.access.redhat.com/ubi9/ubi:latest as base

FROM base as base-amd64
ENV NVARCH x86_64
ENV NVIDIA_REQUIRE_CUDA "cuda>=12.3 brand=tesla,driver>=470,driver<471 ... driver<536"
ENV NV_CUDA_CUDART_VERSION 12.3.52-1
COPY cuda.repo-x86_64 /etc/yum.repos.d/cuda.repo

FROM base as base-arm64
ENV NVARCH sbsa
ENV NVIDIA_REQUIRE_CUDA "CUDA>=12.3"
ENV NV_CUDA_CUDART_VERSION 12.3.52-1
COPY cuda.repo-arm64 /etc/yum.repos.d/cuda.repo

ARG TARGETARCH
FROM base-${TARGETARCH}

LABEL maintainer "NVIDIA CORPORATION <sw-cuda-installer@nvidia.com>"

RUN NVIDIA_GPGKEY_SUM=d0664fbbdb8c32356d45de36c5984617217b2d0bef41b93ccecd326ba3b80c87 && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/rhel9/${NVARCH}/D42D0685.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA && \
    echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c --strict -

ENV CUDA_VERSION 12.3.0

RUN yum upgrade -y && yum install -y \
    cuda-cudart-12-3-${NV_CUDA_CUDART_VERSION} \
    cuda-compat-12-3 \
    && yum clean all \
    && rm -rf /var/cache/yum/*

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

# --nvidia-container customizations start here--

# Create a non-root user
RUN useradd -ms /bin/bash vllm

# Install wget and Miniconda as non-root
RUN mkdir -p /home/vllm/miniconda3 && \
    chown vllm:vllm /home/vllm/miniconda3 && \
    yum install -y wget
USER vllm
WORKDIR /home/vllm/miniconda3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -u -p /home/vllm/miniconda3 && \
    rm -rf miniconda.sh

# Install vllm package and dependencies
COPY requirements.txt /tmp/
RUN //home/vllm/miniconda3/bin/pip install -r /tmp/requirements.txt

#Set the path and library path environment
ENV PATH /home/vllm/miniconda3/bin:/home/vllm/miniconda3/lib/python3.11/site-packages/vllm:/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

#Copy the Nvidia license file to the container
COPY NGC-DL-CONTAINER-LICENSE /

#Set Nvidia environment variables
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility